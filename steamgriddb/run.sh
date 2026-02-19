#!/bin/bash

# Get API Key from the first argument
API_KEY="$1"
ROM_DIR="/userdata/roms/steam"

# Validation
if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

if [ ! -d "$ROM_DIR" ]; then
    echo "Error: Directory $ROM_DIR not found."
    exit 1
fi

cd "$ROM_DIR" || exit

# Loop through .steam files
for file in *.steam; do
    [[ "$file" == "Steam.steam" ]] && continue
    [ -f "$file" ] || continue

    # 1. Extract the AppID from the file content using regex
    # Looks for the digits after steam://rungameid/
    app_id=$(grep -oP '(?<=steam://rungameid/)\d+' "$file")
    
    # Fallback: if regex fails, skip the file
    if [ -z "$app_id" ]; then
        echo "   ! Could not find AppID inside $file. Skipping."
        continue
    fi

    # The prefix for our saved images (using the .steam filename without extension)
    game_prefix="${file%.*}"
    
    # Check if we already have the assets for this specific filename
    if ls "${game_prefix}-image".* 1>/dev/null 2>&1 && \
       ls "${game_prefix}-thumb".* 1>/dev/null 2>&1 && \
       ls "${game_prefix}-marquee".* 1>/dev/null 2>&1; then
        echo "--> Skipping $game_prefix: Assets already exist."
        continue
    fi

    echo "Processing $game_prefix (AppID: $app_id)..."

    # 2. Get the SteamGridDB Game ID using the extracted AppID
    search_res=$(curl -s -X GET "https://www.steamgriddb.com/api/v2/games/steam/$app_id" \
        -H "Authorization: Bearer $API_KEY")

    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match found on SteamGridDB for AppID $app_id"
        continue
    fi

    fetch() {
        local endpoint=$1
        local label=$2 # e.g., -image, -thumb
        
        url=$(curl -s -X GET "https://www.steamgriddb.com/api/v2/$endpoint/game/$db_id" \
            -H "Authorization: Bearer $API_KEY" | grep -oP '(?<="url":")[^"]+' | head -n 1)

        if [ -n "$url" ]; then
            ext="${url##*.}"
            ext="${ext%%\?*}" 
            target_file="${game_prefix}${label}.${ext}"
            
            if [ -f "$target_file" ]; then
                echo "   - $label already exists ($ext). Skipping."
            else
                curl -s -L -o "$target_file" "$url"
                echo "   + Downloaded $target_file"
            fi
        fi
    }

    fetch "grids" "-image"
    fetch "heroes" "-thumb"
    fetch "logos" "-marquee"
done

echo "Operation complete."