#!/usr/bin/env bash
# ── Second Brain Launcher ──────────────────────────────────────────────────────
# Just run:  bash run.sh
# Everything else is handled automatically.

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Always run from the project directory
cd "$(dirname "$0")"

echo ""
echo -e "${CYAN}${BOLD}  second brain${RESET}${CYAN} — starting up...${RESET}"
echo ""

# ── 1. Check setup ────────────────────────────────────────────────────────────
if [ ! -d "second-brain-env" ]; then
  echo -e "${RED}  ✗ Not set up yet.${RESET}"
  echo -e "  Run this first:  ${BOLD}bash setup.sh${RESET}"
  echo ""
  exit 1
fi

# ── 2. Start Ollama if not already running ────────────────────────────────────
if curl -s http://localhost:11434 &>/dev/null; then
  echo -e "${GREEN}  ✓ Ollama is running${RESET}"
else
  echo -e "${YELLOW}  ↻ Starting Ollama in background...${RESET}"
  ollama serve &>/dev/null &
  # Wait up to 10 s for Ollama to be ready
  for i in $(seq 1 10); do
    sleep 1
    if curl -s http://localhost:11434 &>/dev/null; then break; fi
  done
  if curl -s http://localhost:11434 &>/dev/null; then
    echo -e "${GREEN}  ✓ Ollama ready${RESET}"
  else
    echo -e "${RED}  ✗ Ollama did not start. Try running: ollama serve${RESET}"
    exit 1
  fi
fi

# ── 3. Activate venv & launch ─────────────────────────────────────────────────
source second-brain-env/bin/activate

echo -e "${GREEN}  ✓ Opening browser at ${BOLD}http://localhost:5050${RESET}"
echo -e "${CYAN}  Press Ctrl+C to stop.${RESET}"
echo ""

python main.py