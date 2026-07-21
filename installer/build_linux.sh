#!/usr/bin/env bash
# ====================================================================
# PC Control Automated Linux Package Builder (Kali Linux / Ubuntu / Debian)
# ====================================================================

set -e

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
OUTPUT_DIR="$PROJECT_ROOT/installer/Output"
DIST_DIR="$OUTPUT_DIR/pc_control_linux"

echo "=== [1/4] Preparing Output Directories ==="
mkdir -p "$DIST_DIR"

echo "=== [2/4] Building Flutter Desktop Linux Binary ==="
cd "$PROJECT_ROOT/mobile_app"
flutter pub get
flutter build linux --release

echo "=== [3/4] Packaging Application Files ==="
cp -r build/linux/x64/release/bundle/* "$DIST_DIR/"
cp -r "$PROJECT_ROOT/backend" "$DIST_DIR/backend"

# Create launcher script inside dist
cat << 'EOF' > "$DIST_DIR/start_pc_control.sh"
#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Launch Backend Agent in Background
(cd backend && ./start_agent.sh) &

# Launch Desktop GUI App
./mobile_app &
EOF

chmod +x "$DIST_DIR/start_pc_control.sh"
chmod +x "$DIST_DIR/backend/start_agent.sh"

echo "=== [4/4] Creating PC_Control_Linux_v1.0.0.tar.gz Archive ==="
cd "$OUTPUT_DIR"
tar -czvf PC_Control_Linux_v1.0.0.tar.gz pc_control_linux

echo "=== SUCCESS! Linux Installer Bundle Created at $OUTPUT_DIR/PC_Control_Linux_v1.0.0.tar.gz ==="
