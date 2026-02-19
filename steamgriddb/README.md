# 🖼️ Batocera SteamGridDB Scraper

This repository provides a lightweight script to automatically fetch high-quality artwork (Grids, Heroes, and Logos) from SteamGridDB for your custom Steam shortcuts in Batocera.

The script scans your /userdata/roms/steam/ folder, identifies your games by their App ID, and downloads the missing assets using your personal API key.

## 🚀 Usage
To run the scraper, you will need your SteamGridDB API Key. You can find or generate one in your SteamGridDB Settings.

Run the following command via SSH or the Batocera terminal (F4):

```bash
curl -L https://raw.githubusercontent.com/fehteh/batocera-scripts/main/steamgriddb/run.sh | bash -s -- YOUR_API_KEY_HERE
```

## 🛠 Features
- Smart Skipping: Automatically ignores Steam.steam and skips games that already have existing artwork to save your API quota.
- Format Detection: Dynamically detects if the source image is a .png, .jpg, or .webp and saves it with the correct extension.
- Batocera Naming Convention: Saves files using the standard suffixes required for the Batocera/EmulationStation UI:

Grids: <appid>-image.*

Heroes: <appid>-thumb.*

Logos: <appid>-marquee.*

## 📂 Requirements
- Batocera v30+ (or any build with curl and grep support).
- A valid SteamGridDB API Key.
- Steam shortcuts located in /userdata/roms/steam/*.steam.