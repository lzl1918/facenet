param(
    [string]$mode = "test"
)

$exp = "$PSScriptRoot/train.ps1 " +
       "-mode $mode " +
       "-modelOut '/home/hake/models/custom/classifier.pkl' " +
       "-raw '/home/hake/datasets/custom/face_aligned' " +
       "-train '/home/hake/datasets/custom/train' " + 
       "-test '/home/hake/datasets/custom/test'"
Invoke-Expression $exp