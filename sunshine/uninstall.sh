#!/bin/bash

# --- Configuration ---
SERVICE_DIR="/userdata/system/services"
SERVICE_NAME="sunshine"
FLATPAK_ID="dev.lizardbyte.app.Sunshine"

echo "--- Batocera Sunshine Uninstaller ---"

# 1. Stop the service if it's currently running
if [ -f "$SERVICE_DIR/$SERVICE_NAME" ]; then
    echo "Stopping Sunshine service..."
    # Using the full path to ensure it hits the right script
    "$SERVICE_DIR/$SERVICE_NAME" stop
fi

# 2. Remove the Batocera service script
if [ -f "$SERVICE_DIR/$SERVICE_NAME" ]; then
    echo "Removing service script from $SERVICE_DIR..."
    rm "$SERVICE_DIR/$SERVICE_NAME"
else
    echo "Service script not found, skipping."
fi

# 3. Uninstall the Flatpak
# --delete-data ensures user configs/logs are wiped too
echo "Uninstalling Sunshine Flatpak and clearing data..."
flatpak uninstall $FLATPAK_ID -y --delete-data

# 4. Optional: Clean up unused Flatpak runtimes
echo "Cleaning up unused Flatpak runtimes..."
flatpak uninstall --unused -y

# 5. Finalize
echo "-------------------------------------------------------"
echo "Sunshine has been completely removed."
echo "You may need to restart EmulationStation for the menu to update."
echo "-------------------------------------------------------"