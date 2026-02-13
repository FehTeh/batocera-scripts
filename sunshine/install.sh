#!/bin/bash

# --- Configuration ---
SERVICE_DIR="/userdata/system/services"
SERVICE_NAME="sunshine"
FLATPAK_ID="dev.lizardbyte.app.Sunshine"

echo "--- Batocera Sunshine Flatpak Installer ---"

# 1. Install Sunshine via Flatpak
# We force '--system' and '--noninteractive' to bypass the choice prompt
echo "Checking/Installing Sunshine Flatpak (System Scope)..."
flatpak install --system --noninteractive flathub $FLATPAK_ID -y

# 2. Create Services directory if it doesn't exist
mkdir -p "$SERVICE_DIR"

# 3. Create the Service Script
echo "Creating Batocera service: $SERVICE_NAME"
cat << 'EOF' > "$SERVICE_DIR/$SERVICE_NAME"
#!/bin/bash
# Batocera Service Script for Sunshine

case "$1" in
    start)
        # Ensure uinput is accessible for controllers
        chmod 666 /dev/uinput 2>/dev/null
        # Run Flatpak in the background
        flatpak run dev.lizardbyte.app.Sunshine > /dev/null 2>&1 &
        ;;
    stop)
        pkill -f sunshine
        ;;
    *)
        exit 1
        ;;
esac
exit 0
EOF

# 4. Set permissions
chmod +x "$SERVICE_DIR/$SERVICE_NAME"

# 5. Finalize
echo "Installation complete!"
echo "-------------------------------------------------------"
echo "1. Restart EmulationStation (or reboot)"
echo "2. Go to: System Settings -> Services -> Sunshine"
echo "3. Toggle it ON"
echo "-------------------------------------------------------"