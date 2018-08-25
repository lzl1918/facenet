param(
    [System.IO.DirectoryInfo]$source="/home/hake/datasets/lfw/raw",
    [System.IO.DirectoryInfo]$destination="/home/hake/datasets/lfw/lfw_mtcnnpy_160"
)
Invoke-Expression "$PSScriptRoot/check.ps1"

(1..4) | ForEach-Object {
    python ./src/align/align_dataset_mtcnn.py `
           $source.FullName `
           $destination.FullName `
           --image_size 160 `
           --margin 32 `
           --random_order `
           --gpu_memory_fraction 0.25
}