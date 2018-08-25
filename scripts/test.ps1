param(
    [System.IO.FileInfo]$image,
    [System.IO.FileInfo]$classifier="/home/hake/models/lfw/classifier.pkl",
    [switch]$noReturn=$false
)
if($image.Exists -eq $false) {
    # search file in the current directory
    $finds = Get-ChildItem -Recurse -Filter $image.Name | ? {$_ -is [System.IO.FileInfo]}
    if($finds.Count -le 0) {
        $filter = "$([System.IO.Path]::GetFileNameWithoutExtension($image.Name)).*"
        $finds = Get-ChildItem -Path "/home/hake/datasets/custom/face_aligned" -Recurse -Filter $filter | ? {$_ -is [System.IO.FileInfo]}
    }
    if($finds.Count -le 0) {
        throw "Image file does not exists"
        return
    }
    else {
        "The request image is not found: $image" | Out-Host
        "Continue with $($finds[0])" | Out-Host
        $image = $finds[0]
    }
}

$dir = "/tmp"
do {
    $randomName = [System.IO.Path]::GetRandomFileName()
    $randomName = [System.IO.Path]::GetFileNameWithoutExtension($randomName)
    $testPath = "$dir/$randomName"
} while((Test-Path $testPath) -eq $true)

Invoke-Expression "$PSScriptRoot/check.ps1"

New-Item $testPath -ItemType Directory | Out-Null
New-Item "$testPath/raw" -ItemType Directory | Out-Null
New-Item "$testPath/raw/test" -ItemType Directory | Out-Null
New-Item "$testPath/aligned" -ItemType Directory | Out-Null
Copy-Item $image.FullName -Destination "$testPath/raw/test/test_001.jpg"

# align
Start-Process python -ArgumentList (
    "./src/align/align_dataset_mtcnn.py",
    "$testPath/raw",
    "$testPath/aligned",
    "--image_size","160",
    "--margin","32",
    "--random_order",
    "--gpu_memory_fraction", "0.25"
) -Wait -NoNewWindow -RedirectStandardOutput "$testPath/align_output.txt" -RedirectStandardError "$testPath/align_err.txt"

# classify
Start-Process "python" -ArgumentList (
    "./src/classifier.py",
    "CLASSIFY",
    "$testPath/aligned",
    "/home/hake/models/facenet/20180402-114759/20180402-114759.pb",
    $classifier,
    "--batch_size", "500"
) -Wait -NoNewWindow -RedirectStandardError "$testPath/classify_err.txt" -RedirectStandardOutput "$testPath/classify_output.txt"

$output = Get-Content "$testPath/classify_output.txt"
if($output.Count -eq 7) {
    $result = New-Object "PSObject" -Property @{
        "Label"= 'None'
        "Score"= 0
    }
}
else {
    $output = $output[$output.Count - 2].Trim()
    while($output[0] -match '\d') {
        $output = $output.Substring(1)
    }
    while($output[0] -match '\s') {
        $output = $output.Substring(1)
    }
    $splited = $output.Split(':')
    $result = New-Object "PSObject" -Property @{
        "Label"=[regex]::Replace($splited[0].Trim(), "\s", '_')
        "Score"=[double]::Parse($splited[1].Trim())
    }
}
if(($dir.Length -ge 2) -and ($testPath.StartsWith($dir))) {
    rm -rf $testPath
}
if($noReturn) {
    Write-Output $result.Score
    Write-Output $result.Label
}
else {
    return $result
}