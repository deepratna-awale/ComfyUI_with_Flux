#!/bin/bash
# Downloads the public companion models for Flux that used to be baked into the with-flux image:
# text encoders, example LoRAs and the openpose annotators.
# Runs in the background on every pod start when the Flux model is present on the volume
# (see start.sh); files that already exist are skipped. Downloads are atomic and parallel.

download_file() {
    local dir=$1
    local file=$2
    local url=$3

    mkdir -p "$dir"
    if [ -f "$dir/$file" ]; then
        echo "$dir/$file already exists, skipping."
        return 0
    fi
    echo "Downloading $file..."
    if wget -q -c -O "$dir/$file.part" "$url"; then
        mv "$dir/$file.part" "$dir/$file"
        echo "Finished $file."
    else
        echo "ERROR: download of $file failed, will retry on next pod start."
        rm -f "$dir/$file.part"
        return 1
    fi
}

ANNOTATORS="/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/lllyasviel/Annotators"

download_file "/ComfyUI/models/clip"        "clip_l.safetensors"                        "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true" &
download_file "/ComfyUI/models/clip"        "t5xxl_fp8_e4m3fn.safetensors"              "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors?download=true" &
download_file "/ComfyUI/models/loras"       "GracePenelopeTargaryenV5.safetensors"      "https://huggingface.co/WouterGlorieux/GracePenelopeTargaryenV5/resolve/main/GracePenelopeTargaryenV5.safetensors?download=true" &
download_file "/ComfyUI/models/loras"       "VideoAditor_flux_realism_lora.safetensors" "https://huggingface.co/VideoAditor/Flux-Lora-Realism/resolve/main/flux_realism_lora.safetensors?download=true" &
download_file "/ComfyUI/models/xlabs/loras" "Xlabs-AI_flux-RealismLora.safetensors"     "https://huggingface.co/XLabs-AI/flux-RealismLora/resolve/main/lora.safetensors?download=true" &
download_file "$ANNOTATORS"                 "body_pose_model.pth"                       "https://huggingface.co/lllyasviel/Annotators/resolve/main/body_pose_model.pth?download=true" &
download_file "$ANNOTATORS"                 "hand_pose_model.pth"                       "https://huggingface.co/lllyasviel/Annotators/resolve/main/hand_pose_model.pth?download=true" &
download_file "$ANNOTATORS"                 "facenet.pth"                               "https://huggingface.co/lllyasviel/Annotators/resolve/main/facenet.pth?download=true" &

wait
echo "Flux companion model downloads done."
