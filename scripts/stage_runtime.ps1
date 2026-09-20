$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Stage = Join-Path $Root 'build\stage'
$Runtime = Join-Path $Stage 'runtime'
$AppStage = Join-Path $Stage 'app'
$Cache = Join-Path $Root 'build\cache'
$PythonVersion = '3.12.10'
$PythonZip = Join-Path $Cache "python-$PythonVersion-embed-amd64.zip"
$PythonUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-embed-amd64.zip"
$GetPip = Join-Path $Cache 'get-pip.py'

Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $Runtime,$AppStage,$Cache | Out-Null

if (-not (Test-Path $PythonZip)) {
    Write-Host "Downloading Python $PythonVersion embeddable runtime..."
    Invoke-WebRequest -Uri $PythonUrl -OutFile $PythonZip -UseBasicParsing
}
Expand-Archive -Path $PythonZip -DestinationPath $Runtime -Force

$Pth = Join-Path $Runtime 'python312._pth'
$PthText = Get-Content $Pth -Raw
$PthText = $PthText -replace '#import site','import site'
if ($PthText -notmatch 'Lib\\site-packages') {
    $PthText = $PthText.TrimEnd() + "`r`nLib\site-packages`r`n"
}
Set-Content -Path $Pth -Value $PthText -Encoding ASCII

if (-not (Test-Path $GetPip)) {
    Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile $GetPip -UseBasicParsing
}

& (Join-Path $Runtime 'python.exe') $GetPip --disable-pip-version-check --timeout 120
& (Join-Path $Runtime 'python.exe') -m pip install --disable-pip-version-check --no-cache-dir --timeout 120 --retries 5 -r (Join-Path $Root 'requirements-runtime.txt')

Copy-Item (Join-Path $Root 'app\*') $AppStage -Recurse -Force
Copy-Item (Join-Path $Root 'VERSION') (Join-Path $Stage 'VERSION') -Force
Copy-Item (Join-Path $Root 'THIRD_PARTY.md') (Join-Path $Stage 'THIRD_PARTY.md') -Force

$env:PYTHONPATH = Join-Path $AppStage 'src'
& (Join-Path $Runtime 'python.exe') -m compileall -q (Join-Path $AppStage 'src')
& (Join-Path $Runtime 'python.exe') -c "import requests, PIL, qrcode, Crypto, openpyxl, docx, pptx, pandas, matplotlib, psutil, deepseek_harness; import win32crypt, win32com.client; print('RUNTIME_IMPORTS_OK')"
& (Join-Path $Runtime 'python.exe') (Join-Path $Root 'scripts\selfcheck.py')

Write-Host "Stage ready: $Stage"
