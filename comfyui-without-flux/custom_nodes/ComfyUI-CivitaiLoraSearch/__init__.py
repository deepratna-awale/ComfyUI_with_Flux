"""Civitai LoRA Search: turns a character into a download manifest for ComfyUI-Model-Batch-Downloader.

It first checks the Civitai link suggested by an LLM (Grok) against the Civitai API, and searches
Civitai by name when the suggestion is missing or doesn't match the character. Finding the LoRA is
all it does; downloading and loading it are left to Model Download Batch (JSON) and
Load LoRA (Downloaded). No ComfyUI-Manager pack searches Civitai inside a running workflow."""

import json
import math
import re
import urllib.error
import urllib.parse
import urllib.request

API = "https://civitai.com/api/v1/models"
BASE_MODELS = {
    "Illustrious": ["Illustrious", "NoobAI"],
    "Pony": ["Pony"],
    "SDXL 1.0": ["SDXL 1.0"],
    "SD 1.5": ["SD 1.5"],
}
# Used when no character LoRA is found, so a batch keeps going: Face Enhancer Illustrious by roxin282
FALLBACK_URL = "https://civitai.red/api/download/models/1839268"


def _tokens(text):
    return set(t for t in re.split(r"[^a-z0-9]+", text.lower()) if len(t) >= 2)


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "ComfyUI-CivitaiLoraSearch"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


class CivitaiLoraSearch:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "tags": ("STRING", {"forceInput": True, "tooltip": "Comma-separated tags; the first is the character, the second the series"}),
                "base_model": (list(BASE_MODELS), {"default": "Illustrious"}),
                "id": ("STRING", {"default": "character_lora", "tooltip": "Manifest id for Load LoRA (Downloaded)"}),
                "fallback_url": ("STRING", {"default": FALLBACK_URL, "tooltip": "Downloaded when nothing matches; empty = fail instead"}),
            },
            "optional": {
                "suggestion": ("STRING", {"forceInput": True, "tooltip": "Text holding a Civitai model link, e.g. from Grok. Used when it matches the character."}),
            },
        }

    RETURN_TYPES = ("STRING", "STRING", "STRING")
    RETURN_NAMES = ("manifest_json", "trigger_words", "civitai_url")
    FUNCTION = "search"
    CATEGORY = "loaders/civitai"

    def search(self, tags, base_model, id, fallback_url, suggestion=""):
        parts = [p.strip() for p in tags.replace("\n", ",").split(",") if p.strip()]
        character = re.sub(r"\s*\(.*?\)", "", (parts[0] if parts else "").replace("\\", "")).strip()
        series = parts[1] if len(parts) > 1 else ""
        bases = BASE_MODELS[base_model]
        want, series_want = _tokens(character), _tokens(series)

        def version_for(model, version_id=None):
            return next((v for v in model.get("modelVersions", []) if v.get("baseModel") in bases
                         and (version_id is None or v.get("id") == version_id)), None)

        def matches(model, version):
            have = _tokens(model.get("name", "") + " " + " ".join(model.get("tags", []))
                           + " " + " ".join(version.get("trainedWords", [])))
            return want <= have, have  # every word of the character name must appear

        best, source = None, ""
        if character and character.lower() not in ("original", "unknown"):
            link = re.search(r"civitai\.(?:com|red)/models/(\d+)\S*?(?:modelVersionId=(\d+))?", suggestion or "")
            if link:
                try:
                    model = _get(f"{API}/{link.group(1)}")
                    version = (version_for(model, int(link.group(2))) if link.group(2) else None) or version_for(model)
                    if model.get("type") == "LORA" and version and matches(model, version)[0]:
                        best, source = (model, version), "suggested"
                except (urllib.error.URLError, ValueError):
                    pass
                if not best:
                    print(f"[Civitai LoRA Search] Suggested model {link.group(1)} is not a {base_model} LoRA of "
                          f"'{character}', searching instead")

            if not best:
                params = [("query", character), ("types", "LORA"), ("sort", "Most Downloaded"), ("limit", "20"),
                          ("nsfw", "true")] + [("baseModels", b) for b in bases]
                best_score = 0.0
                for model in _get(f"{API}?{urllib.parse.urlencode(params)}").get("items", []):
                    version = version_for(model)
                    if not version:
                        continue
                    ok, have = matches(model, version)
                    if not ok:
                        continue
                    score = 3 * bool(series_want & have) + math.log10(1 + model.get("stats", {}).get("downloadCount", 0))
                    if score > best_score:
                        best, best_score, source = (model, version), score, "search"

        if best:
            model, version = best
            url = f"https://civitai.red/api/download/models/{version['id']}"
            words = version.get("trainedWords", [])[:1]
            page = f"https://civitai.com/models/{model['id']}?modelVersionId={version['id']}"
            print(f"[Civitai LoRA Search] {character} ({source}): {model.get('name')} ({page})")
        elif fallback_url.strip():
            url, words, page = fallback_url.strip(), [], ""
            print(f"[Civitai LoRA Search] No {base_model} LoRA for '{character}', using the fallback")
        else:
            raise RuntimeError(f"No {base_model} LoRA found on Civitai for '{character}'")

        manifest = [{"url": url, "model_type": "loras", "subfolder": "civitai_characters", "id": id}]
        return (json.dumps(manifest), ", ".join(words), page)


NODE_CLASS_MAPPINGS = {"CivitaiLoraSearch": CivitaiLoraSearch}
NODE_DISPLAY_NAME_MAPPINGS = {"CivitaiLoraSearch": "Civitai LoRA Search"}
