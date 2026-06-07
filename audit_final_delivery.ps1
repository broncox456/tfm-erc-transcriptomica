Write-Host "=== FINAL DELIVERY AUDIT ==="

Write-Host "`n[ROOT FILES]"
Get-ChildItem -File

Write-Host "`n[FIGURES]"
Get-ChildItem results\figures

Write-Host "`n[TABLES]"
Get-ChildItem results\tables

Write-Host "`n[RUNNING R VALIDATION]"
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts\validate_project_outputs.R

Write-Host "`n=== AUDIT COMPLETED ==="
