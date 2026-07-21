#!/usr/bin/env bash
# ====================================================================
# PC Control Backend Agent Launcher for Linux (Kali / Ubuntu / Debian)
# ====================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "[PC Control] Initializing Linux Backend Agent..."

# Check and create virtual environment or fallback to system pip
if [ ! -f ".venv/bin/activate" ]; then
    echo "[PC Control] Creating virtual environment..."
    python3 -m venv .venv 2>/dev/null || true
fi

if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    pip install -q -r requirements.txt 2>/dev/null || python3 -m pip install -q -r requirements.txt 2>/dev/null || true
else
    echo "[PC Control] Installing dependencies via system python3 pip..."
    python3 -m pip install -q -r requirements.txt --break-system-packages 2>/dev/null || pip3 install -q -r requirements.txt 2>/dev/null || true
fi

# Launch Agent Client
echo "[PC Control] Starting Agent Client..."
if [ -f ".venv/bin/python3" ]; then
    .venv/bin/python3 agent_client.py
else
    python3 agent_client.py
fi
