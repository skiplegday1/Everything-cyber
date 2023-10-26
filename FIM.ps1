Function ComputeFileHash($path) {
    $fileHashResult = Get-FileHash -Path $path -Algorithm SHA512
    return $fileHashResult
}
Function RemoveBaselineIfExists() {
    $baselineCheck = Test-Path -Path .\baseline.txt

    if ($baselineCheck) {
        Remove-Item -Path .\baseline.txt
    }
}

Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "    A) Collect new Baseline?"
Write-Host "    B) Begin monitoring files with saved Baseline?"
Write-Host ""
$userResponse = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""

if ($userResponse -eq "A".ToUpper()) {
    RemoveBaselineIfExists

    $filesToInspect = Get-ChildItem -Path .\Files

    foreach ($fileToInspect in $filesToInspect) {
        $hashResult = ComputeFileHash $fileToInspect.FullName
        "$($hashResult.Path)|$($hashResult.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}

elseif ($userResponse -eq "B".ToUpper()) {
    $hashDictionary = @{}

    $baselineFileContents = Get-Content -Path .\baseline.txt

    foreach ($content in $baselineFileContents) {
         $hashDictionary.add($content.Split("|")[0],$content.Split("|")[1])
    }

    while ($true) {
        Start-Sleep -Seconds 1
        
        $filesToMonitor = Get-ChildItem -Path .\Files

        foreach ($fileToMonitor in $filesToMonitor) {
            $hashResult = ComputeFileHash $fileToMonitor.FullName

            if ($hashDictionary[$hashResult.Path] -eq $null) {
                Write-Host "$($hashResult.Path) has been created!" -ForegroundColor Green
            }
            else {
                if ($hashDictionary[$hashResult.Path] -eq $hashResult.Hash) {
                    # The file has not changed
                }
                else {
                    Write-Host "$($hashResult.Path) has changed!!!" -ForegroundColor Yellow
                }
            }
        }

        foreach ($key in $hashDictionary.Keys) {
            $baselineFileExists = Test-Path -Path $key
            if (-Not $baselineFileExists) {
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }
}
