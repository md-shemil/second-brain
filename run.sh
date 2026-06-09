#!/usr/bin/env bash
# Quick launcher — activates venv and starts Second Brain

cd "$(dirname "$0")"

if [ ! -d "venv" ]; then
  echo "Run setup first: bash setup.sh"
  exit 1
fi

source venv/bin/activate
python main.py