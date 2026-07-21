#!/usr/bin/env bash
# ====================================================================
# PC Control Backend Agent Launcher for Linux (Kali / Ubuntu / Debian)
# ====================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "[PC Control] Initializing Linux Backend Agent..."

# Create Python Virtual Environment if missing
if [ ! -d ".venv" ]; then
    echo "[PC Control] Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate Virtual Environment
source .venv/bin/activate

# Install requirements if needed
echo "[PC Control] Checking dependencies..."
pip install -q -r requirements.txt

# Launch Agent Client
echo "[PC Control] Starting Agent Client..."
python3 agent_client.py
