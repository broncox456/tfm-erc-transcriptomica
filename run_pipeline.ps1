$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

$Rscript = "C:\Program Files\R\R-4.5.2\bin\Rscript.exe"

if (!(Test-Path $Rscript)) {
    throw "Rscript.exe not found at: $Rscript"
}

New-Item -ItemType Directory -Force -Path logs | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$log = "logs\powershell_pipeline_$timestamp.log"

"TFM ERC transcriptomics pipeline" | Tee-Object -FilePath $log
"Timestamp: $timestamp" | Tee-Object -FilePath $log -Append
"Project root: $ProjectRoot" | Tee-Object -FilePath $log -Append
"Rscript: $Rscript" | Tee-Object -FilePath $log -Append

& $Rscript scripts/run_pipeline.R 2>&1 | Tee-Object -FilePath $log -Append

if ($LASTEXITCODE -ne 0) {
    throw "Pipeline failed. Review log: $log"
}

"Pipeline finished successfully." | Tee-Object -FilePath $log -Append
