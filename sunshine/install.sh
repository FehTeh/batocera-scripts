#!/bin/bash

# --- Configuration ---
SERVICE_DIR="/userdata/system/services"
SERVICE_NAME="Sunshine"
FLATPAK_ID="dev.lizardbyte.sunshine"

echo "--- Batocera Sunshine Flatpak Installer ---"

# 1. Install Sunshine via Flatpak
echo "Installing Sunshine Flatpak..."
flatpak install flathub $FLATPAK_ID -y

# 2. Create Services directory if it doesn't exist
mkdir -p "$SERVICE_DIR"

# 3. Create the Service Script
echo "Creating Batocera service: $SERVICE_NAME"
cat << 'EOF' > "$SERVICE_DIR/$SERVICE_NAME"
#!/bin/bash
# Batocera Service Script for Sunshine

case "$1" in
    start)
        # Fix uinput permissions for controller support
        chmod 666 /dev/uinput 2>/dev/null
        # Run Flatpak in the background
        flatpak run dev.lizardbyte.sunshine > /dev/null 2>&1 &
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
echo "You can now enable Sunshine in:"
echo "System Settings -> Services -> Sunshine"
echo "-------------------------------------------------------"
echo "Or start it now manually with: batocera-services start $SERVICE_NAME"