$pythonPath = [System.Environment]::GetEnvironmentVariable("PYTHONPATH")
if($pythonPath -eq $null) {
    [System.Environment]::SetEnvironmentVariable("PYTHONPATH", "/home/hake/dev/facenet/src")
}