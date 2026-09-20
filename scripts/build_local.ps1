$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
.\scripts\fetch_office_skills.ps1
.\scripts\stage_runtime.ps1
$iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $iscc)) { throw "Inno Setup 6 not found: $iscc" }
& $iscc .\installer\xiaozhi.iss
if ($LASTEXITCODE -ne 0) { throw "ISCC failed: $LASTEXITCODE" }
Write-Host "Built: $Root\dist\XiaoZhiSetup.exe"
