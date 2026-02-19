#!/bin/bash

API_KEY="$1"
ROM_DIR="/userdata/roms/steam"

if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

cd "$ROM_DIR" || exit

for file in *.steam; do
    [[ "$file" == "Steam.steam" ]] && continue
    [ -f "$file" ] || continue

    game_id="${file%.*}"
    
    # Check if we already have the assets (any extension)
    if ls "${game_id}-image".* 1>/dev/null 2>&1 && \
       ls "${game_id}-thumb".* 1>/dev/null 2>&1 && \
       ls "${game_id}-marquee".* 1>/dev/null 2>&1; then
        echo "--> Skipping $game_id: Assets already exist."
        continue
    fi

    echo "Processing $game_id..."

    search_res=$(curl -s -X GET "https://www.steamgriddb.com/api/v2/games/steam/$game_id" \
        -H "Authorization: Bearer $API_KEY")
    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match found for $game_id"
        continue
    fi

    fetch() {
        local endpoint=$1
        local label=$2 # e.g., -image, -thumb
        
        # Get the URL
        url=$(curl -s -X GET "https://www.steamgriddb.com/api/v2/$endpoint/game/$db_id" \
            -H "Authorization: Bearer $API_KEY" | grep -oP '(?<="url":")[^"]+' | head -n 1)

        if [ -n "$url" ]; then
            # Extract the actual extension from the URL (e.g., png, jpg, webp)
            ext="${url##*.}"
            # Clean extension of any URL parameters (rare but safe)
            ext="${ext%%\?*}" 
            
            target_file="${game_id}${label}.${ext}"
            
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

echo "Done!"