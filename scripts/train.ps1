param(
    [string]$mode = "test",
    [System.IO.FileInfo]$model = "/home/hake/models/facenet/20180402-114759/20180402-114759.pb",
    [System.IO.FileInfo]$modelOut = "/home/hake/models/lfw/classifier.pkl",
    [System.IO.DirectoryInfo]$raw = "/home/hake/datasets/lfw/lfw_mtcnnpy_160",
    [System.IO.DirectoryInfo]$train = "/home/hake/datasets/lfw_train",
    [System.IO.DirectoryInfo]$test = "/home/hake/datasets/lfw_test",
    [int]$batchSize=500
)
Invoke-Expression "$PSScriptRoot/check.ps1"
function Extract-TestTrainSet([System.IO.DirectoryInfo]$raw, [System.IO.DirectoryInfo]$train, [System.IO.DirectoryInfo]$test) {
    if(!$raw.Exists) {
        throw "directory for raw dataset does not exist. the path is $($raw.FullName)"
    }
    if(!$train.Exists) {
        throw "directory for train dataset does not exist. the path is $($train.FullName)"
    }
    if(!$test.Exists) {
        throw "directory for test dataset does not exist. the path is $($test.FullName)"
    }
    Write-Host "Extract training and test dataset"
    $faces = Get-ChildItem $raw.FullName | Where-Object {($_ -is [System.IO.DirectoryInfo]) -and ((dir $_.FullName).Count -ge 8)}

    $faces | ForEach-Object {
        $people = Get-ChildItem $_.FullName
        $outTest = "$test/$($_.Name)"
        $outTrain = "$train/$($_.Name)"
        if(!(Test-Path $outTest)) {New-Item $outTest -ItemType Directory | Out-Null}
        if(!(Test-Path $outTrain)) {New-Item $outTrain -ItemType Directory | Out-Null}
        if($people -is [System.IO.FileInfo]) {
            Copy-Item -Path $people.FullName -Destination $outTest
            Copy-Item -Path $people.FullName -Destination $outTrain
        }
        else {
            $count = $people.Length
            $testCount = [int]([System.Math]::Floor($count / 2))
            $tests = $people[0..$testCount]
            $trains = $people[$testCount..$count]
            $tests | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $outTest
            }
            $trains | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $outTrain
            }
        }
    }

    Write-Host "Extraction completed"
}

if(![System.IO.Directory]::Exists($raw)) {
    throw "raw path does not exist"
}

if([System.IO.Directory]::Exists($train) -and [System.IO.Directory]::Exists($test)) {
    if((Get-ChildItem $train).Length -le 0) {
        Extract-TestTrainSet -raw $raw -train $train -test $test
    }
}
else {
    if(![System.IO.Directory]::Exists($train)) {New-Item $train -ItemType Directory | Out-Null}
    if(![System.IO.Directory]::Exists($test)) {New-Item $test -ItemType Directory | Out-Null}

    Extract-TestTrainSet -raw $raw -train $train -test $test
}
$mode = $mode.ToUpper()

switch($mode) {
    "TRAIN" {
        $command = "python src/classifier.py $mode $train $model $modelOut --batch_size $batchSize"
    }
    "TEST" {
        $command = "python src/classifier.py CLASSIFY $test $model $modelOut --batch_size $batchSize"
    }
    Default {
        Write-Warning "unknown mode"
        return
    }
}
Write-Host $mode
Invoke-Expression $command
