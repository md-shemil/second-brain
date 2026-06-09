#!/usr/bin/env bash
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ███████╗███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗     ██████╗ ██████╗  █████╗ ██╗███╗   ██╗"
echo "  ██╔════╝██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗    ██╔══██╗██╔══██╗██╔══██╗██║████╗  ██║"
echo "  ███████╗█████╗  ██║     ██║   ██║██╔██╗ ██║██║  ██║    ██████╔╝██████╔╝███████║██║██╔██╗ ██║"
echo "  ╚════██║██╔══╝  ██║     ██║   ██║██║╚██╗██║██║  ██║    ██╔══██╗██╔══██╗██╔══██║██║██║╚██╗██║"
echo "  ███████║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝    ██████╔╝██║  ██║██║  ██║██║██║ ╚████║"
echo "  ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝"
echo -e "${RESET}"
echo -e "${CYAN}  Local AI · Private · No Cloud · One-Command Setup${RESET}"
echo ""

# ── OS detection ──────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux*)  PLATFORM="linux" ;;
  Darwin*) PLATFORM="mac" ;;
  *)       echo -e "${RED}Unsupported OS: $OS${RESET}"; exit 1 ;;
esac
echo -e "${CYAN}▶ Detected platform: ${BOLD}$PLATFORM${RESET}"

# ── Python check ──────────────────────────────────────────────────────────────
echo -e "${CYAN}▶ Checking Python...${RESET}"
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}Python3 not found. Install from https://python.org${RESET}"; exit 1
fi
PYVER=$(python3 --version 2>&1)
echo -e "${GREEN}  ✓ $PYVER${RESET}"

# ── Ollama install ────────────────────────────────────────────────────────────
echo -e "${CYAN}▶ Checking Ollama...${RESET}"
if ! command -v ollama &>/dev/null; then
  echo -e "${YELLOW}  Ollama not found. Installing...${RESET}"
  if [ "$PLATFORM" = "linux" ]; then
    curl -fsSL https://ollama.com/install.sh | sh
  elif [ "$PLATFORM" = "mac" ]; then
    if command -v brew &>/dev/null; then
      brew install ollama
    else
      echo -e "${YELLOW}  Homebrew not found. Downloading Ollama manually...${RESET}"
      curl -L https://ollama.com/download/Ollama-darwin.zip -o /tmp/Ollama.zip
      unzip -q /tmp/Ollama.zip -d /tmp/
      mv /tmp/Ollama.app /Applications/Ollama.app
      echo -e "${YELLOW}  Ollama installed to /Applications. Launch it once manually, then re-run this script.${RESET}"
      exit 0
    fi
  fi
else
  echo -e "${GREEN}  ✓ Ollama already installed${RESET}"
fi

# ── Start Ollama in background if not running ─────────────────────────────────
if ! curl -s http://localhost:11434 &>/dev/null; then
  echo -e "${CYAN}▶ Starting Ollama server...${RESET}"
  ollama serve &>/dev/null &
  sleep 3
else
  echo -e "${GREEN}  ✓ Ollama already running${RESET}"
fi

# ── Model selection ───────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Choose your LLM model:${RESET}"
echo "  1) llama3        — 4GB  · Smart, detailed answers"
echo "  2) llama3.2      — 2GB  · Faster, lighter"
echo "  3) mistral       — 4GB  · Great for reasoning"
echo "  4) phi3          — 2GB  · Tiny but capable"
echo "  5) gemma2        — 5GB  · Google's model"
echo ""
read -rp "  Enter choice [1-5] (default: 1): " MODEL_CHOICE

case "$MODEL_CHOICE" in
  2) LLM_MODEL="llama3.2" ;;
  3) LLM_MODEL="mistral" ;;
  4) LLM_MODEL="phi3" ;;
  5) LLM_MODEL="gemma2" ;;
  *) LLM_MODEL="llama3" ;;
esac

echo -e "${CYAN}▶ Pulling ${BOLD}$LLM_MODEL${RESET}${CYAN} (this may take a while)...${RESET}"
ollama pull "$LLM_MODEL"

echo -e "${CYAN}▶ Pulling embedding model ${BOLD}nomic-embed-text${RESET}${CYAN}...${RESET}"
ollama pull nomic-embed-text

# ── Update brain.py with chosen model ─────────────────────────────────────────
echo -e "${CYAN}▶ Configuring brain with model: $LLM_MODEL...${RESET}"
sed -i.bak "s/LLM_MODEL = .*/LLM_MODEL = \"$LLM_MODEL\"/" brain.py && rm -f brain.py.bak

# ── Virtual environment ───────────────────────────────────────────────────────
echo -e "${CYAN}▶ Creating virtual environment...${RESET}"
python3 -m venv venv
source venv/bin/activate

echo -e "${CYAN}▶ Installing Python dependencies...${RESET}"
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt

# ── Folders ───────────────────────────────────────────────────────────────────
mkdir -p docs brain

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  ✓ Setup complete! Second Brain is ready.${RESET}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. Drop PDFs/TXTs into the ${CYAN}docs/${RESET} folder"
echo -e "  2. Run: ${CYAN}${BOLD}bash run.sh${RESET}"
echo -e "  3. Click \"Index folder\" in the browser to index your docs"
echo -e "  4. Ask anything!"
echo ""