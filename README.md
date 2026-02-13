# ☀️ Batocera Sunshine Service

This repository provides an automated way to install **Sunshine** (the high-performance game stream host) via Flatpak on Batocera and register it as a native system service.

By using this script, you can toggle Sunshine on or off directly from the **System Settings > Services** menu in the Batocera UI.

---

## 🚀 Installation

To install Sunshine and the service script, run the following command in your Batocera terminal (via SSH or by pressing `F4` on a keyboard):

```bash
curl -L https://raw.githubusercontent.com/fehteh/batocera-scripts/main/sunshine/install.sh | bash
```

## 🛠 Usage

Via the Batocera UI

Open Main Menu (Start).

Go to System Settings > Services.

Toggle Sunshine to ON.

Go to https://<batocera-ip>:47990 to continue configuration

## 🗑 Uninstallation
To remove the Flatpak and the service script:

```bash
curl -L https://raw.githubusercontent.com/fehteh/batocera-scripts/main/sunshine/uninstall.sh | bash
```

Requires Batocera v38+