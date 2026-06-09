# Second Brain - Windows Setup Script
# Run in PowerShell: .\setup.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  Second Brain -- Local AI Setup (Windows)" -ForegroundColor Cyan
Write-Host "  Local AI | Private | No Cloud" -ForegroundColor Cyan
Write-Host ""

# Python check
Write-Host ">> Checking Python..." -ForegroundColor Cyan
try {
    $pyver = & python --version 2>&1
    Write-Host "  OK: $pyver" -ForegroundColor Green
} catch {
    Write-Host "  Python not found. Install from https://python.org" -ForegroundColor Red
    exit 1
}

# Ollama check
Write-Host ">> Checking Ollama..." -ForegroundColor Cyan
$ollamaExists = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollamaExists) {
    Write-Host "  Ollama not found. Downloading installer..." -ForegroundColor Yellow
    $installerPath = "$env:TEMP\OllamaSetup.exe"
    Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $installerPath
    Write-Host "  Running installer (follow the prompts)..." -ForegroundColor Yellow
    Start-Process -FilePath $installerPath -Wait
    Write-Host "  Ollama installed. Please restart PowerShell and run this script again." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "  OK: Ollama already installed" -ForegroundColor Green
}

# Start Ollama if not running
Write-Host ">> Starting Ollama server..." -ForegroundColor Cyan
$ollamaRunning = $false
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:11434" -TimeoutSec 2 -ErrorAction SilentlyContinue
    $ollamaRunning = $true
} catch {}

if (-not $ollamaRunning) {
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}
Write-Host "  OK: Ollama running" -ForegroundColor Green

# Model selection
Write-Host ""
Write-Host "Choose your LLM model:" -ForegroundColor White
Write-Host "  1) llama3      - 4GB  - Smart, detailed answers"
Write-Host "  2) llama3.2    - 2GB  - Faster, lighter"
Write-Host "  3) mistral     - 4GB  - Great for reasoning"
Write-Host "  4) phi3        - 2GB  - Tiny but capable"
Write-Host "  5) gemma2      - 5GB  - Google model"
Write-Host ""
$modelChoice = Read-Host "  Enter choice [1-5] (default: 1)"

switch ($modelChoice) {
    "2" { $LLM_MODEL = "llama3.2" }
    "3" { $LLM_MODEL = "mistral" }
    "4" { $LLM_MODEL = "phi3" }
    "5" { $LLM_MODEL = "gemma2" }
    default { $LLM_MODEL = "llama3" }
}

Write-Host ">> Pulling $LLM_MODEL..." -ForegroundColor Cyan
& ollama pull $LLM_MODEL

Write-Host ">> Pulling nomic-embed-text..." -ForegroundColor Cyan
& ollama pull nomic-embed-text

# Update brain.py with chosen model
Write-Host ">> Configuring model in brain.py..." -ForegroundColor Cyan
(Get-Content brain.py) -replace 'LLM_MODEL = ".*"', "LLM_MODEL = `"$LLM_MODEL`"" | Set-Content brain.py

# Virtual environment
Write-Host ">> Creating virtual environment..." -ForegroundColor Cyan
& python -m venv venv
& .\venv\Scripts\Activate.ps1

Write-Host ">> Installing Python dependencies..." -ForegroundColor Cyan
& pip install --quiet --upgrade pip
& pip install --quiet -r requirements.txt

# Create folders
New-Item -ItemType Directory -Force -Path docs | Out-Null
New-Item -ItemType Directory -Force -Path brain | Out-Null

# Done
Write-Host ""
Write-Host "  ------------------------------------------------" -ForegroundColor Green
Write-Host "  Setup complete! Second Brain is ready." -ForegroundColor Green
Write-Host "  ------------------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Drop PDFs/TXTs into the docs\ folder"
Write-Host "  2. Run:" -NoNewline
Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan -NoNewline
Write-Host " then " -NoNewline
Write-Host "python main.py" -ForegroundColor Cyan
Write-Host "  3. Browser opens at http://localhost:5050"
Write-Host ""