#!/bin/bash

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/download_lib.sh"

echo "Downloading models for the Anime Character Upscale workflow"

download_file "/ComfyUI/models/checkpoints" "waiIllustriousSDXL_v170.safetensors" "https://civitai.com/api/download/models/2883731?type=Model&format=SafeTensor"
download_file "/ComfyUI/models/controlnet" "xinsir_controlnet_union-sdxl-1-promax.safetensors" "https://huggingface.co/xinsir/controlnet-union-sdxl-1.0/resolve/main/diffusion_pytorch_model_promax.safetensors?download=true"
download_file "/ComfyUI/models/ipadapter" "ip-adapter-plus_sdxl_vit-h.safetensors" "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors?download=true"
download_file "/ComfyUI/models/clip_vision" "clip_vision_h.safetensors" "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true"
download_file "/ComfyUI/models/upscale_models" "4x-UltraSharp.pth" "https://huggingface.co/lokCX/4x-Ultrasharp/resolve/main/4x-UltraSharp.pth?download=true"
download_file "/ComfyUI/models/ultralytics/bbox" "face_yolov8m.pt" "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt?download=true"
# The watermark remover would fetch fashn-ai/LaMa on its own, which spandrel cannot load; this is the LaMa it can
download_file "/ComfyUI/models/inpaint" "big-lama.pt" "https://github.com/Sanster/models/releases/download/add_big_lama/big-lama.pt"

download_wait
