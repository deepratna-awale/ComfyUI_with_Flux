#!/bin/bash
# Downloads the public models that used to be baked into the Docker image.
# Runs in the background on every pod start (see start.sh); files that already exist are skipped.
# Each file is downloaded to a .part file and renamed when complete, so ComfyUI never sees a
# half-written model. Downloads run in parallel.

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

download_file "/ComfyUI/models/checkpoints"      "v1-5-pruned-emaonly-fp16.safetensors" "https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors?download=true" &
download_file "/ComfyUI/models/insightface"      "inswapper_128.onnx"                   "https://huggingface.co/ezioruan/inswapper_128.onnx/resolve/main/inswapper_128.onnx?download=true" &
download_file "/ComfyUI/models/ultralytics/bbox" "face_yolov8m.pt"                      "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt?download=true" &

wait
echo "Base model downloads done."
