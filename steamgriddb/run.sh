#!/bin/bash

# Get API Key from the first argument
API_KEY="$1"
ROM_DIR="/userdata/roms/steam"
IMG_DIR="${ROM_DIR}/images"

# Validation
if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

if [ ! -d "$ROM_DIR" ]; then
    echo "Error: Directory $ROM_DIR not found."
    exit 1
fi

# Create images folder if it's missing
mkdir -p "$IMG_DIR"

cd "$ROM_DIR" || exit

for file in *.steam; do
    [[ "$file" == "Steam.steam" ]] && continue
    [ -f "$file" ] || continue

    # Extract AppID from file content
    app_id=$(grep -oP '(?<=steam://rungameid/)\d+' "$file")
    
    if [ -z "$app_id" ]; then
        echo "   ! Could not find AppID inside $file. Skipping."
        continue
    fi

    game_prefix="${file%.*}"
    
    # Check if assets exist in the IMAGES subfolder
    if ls "${IMG_DIR}/${game_prefix}-image".* 1>/dev/null 2>&1 && \
       ls "${IMG_DIR}/${game_prefix}-thumb".* 1>/dev/null 2>&1 && \
       ls "${IMG_DIR}/${game_prefix}-marquee".* 1>/dev/null 2>&1; then
        echo "--> Skipping $game_prefix: Assets already exist in images/."
        continue
    fi

    echo "Processing $game_prefix (AppID: $app_id)..."

    search_res=$(curl -s -X GET "https://www.steamgriddb.com/api/v2/games/steam/$app_id" \
        -H "Authorization: Bearer $API_KEY")
    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match found on SteamGridDB for AppID $app_id"
        continue
    fi

    fetch() {
        local endpoint=$1
        local label=$2
        
        url=$(curl -s -X GET "https://www.steamgriddb.com/api/v2/$endpoint/game/$db_id" \
            -H "Authorization: Bearer $API_KEY" | grep -oP '(?<="url":")[^"]+' | head -n 1)

        if [ -n "$url" ]; then
            ext="${url##*.}"
            ext="${ext%%\?*}" 
            # Define target path inside the images folder
            target_file="${IMG_DIR}/${game_prefix}${label}.${ext}"
            
            if [ -f "$target_file" ]; then
                echo "   - $label already exists in images/. Skipping."
            else
                curl -s -L -o "$target_file" "$url"
                echo "   + Downloaded images/$(basename "$target_file")"
            fi
        fi
    }

    fetch "grids" "-image"
    fetch "heroes" "-thumb"
    fetch "logos" "-marquee"
done

echo "Operation complete."