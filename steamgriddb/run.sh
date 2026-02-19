#!/bin/bash

API_KEY="$1"
ROM_DIR="/userdata/roms/steam"
IMG_DIR="${ROM_DIR}/images"
GAMELIST="${ROM_DIR}/gamelist.xml"

if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

[ ! -f "$GAMELIST" ] && echo "Error: gamelist.xml not found" && exit 1
mkdir -p "$IMG_DIR"
cd "$ROM_DIR" || exit

# Function to safely insert tags into the XML
update_xml_tag() {
    local game_path=$1
    local tag=$2
    local img_path=$3
    
    echo "   * Adding <$tag> to gamelist.xml"
    # Escaping for sed (handles spaces and dots)
    local escaped_path=$(echo "$game_path" | sed 's/[^^]/[&]/g; s/\^/\\^/g')
    
    # This finds the block for the specific game and inserts the tag before the closing </game>
    sed -i "/<path>${escaped_path}<\/path>/,/<\/game>/ s/<\/game>/\t\t<$tag>$img_path<\/$tag>\n\t<\/game>/" "$GAMELIST"
}

# 1. Extract all paths using sed to ignore leading tabs/spaces
paths=$(sed -n 's/.*<path>\(.*\)<\/path>.*/\1/p' "$GAMELIST")

echo "$paths" | while read -r game_path; do
    # Clean hidden Windows characters
    game_path=$(echo "$game_path" | tr -d '\r')

    # Filters
    [[ -z "$game_path" ]] && continue
    [[ "$game_path" != *".steam" ]] && continue
    [[ "$game_path" == *"Steam.steam" ]] && continue

    echo "Checking $game_path..."

    # 2. Grab the specific game block (matching exactly the path provided)
    # We use grep with the variable to find the context
    game_block=$(grep -A 15 "<path>$game_path</path>" "$GAMELIST")
    
    # Check for missing tags
    missing_image=$(echo "$game_block" | grep -q "<image>" || echo "yes")
    missing_thumb=$(echo "$game_block" | grep -q "<thumbnail>" || echo "yes")
    missing_marquee=$(echo "$game_block" | grep -q "<marquee>" || echo "yes")

    if [ "$missing_image" != "yes" ] && [ "$missing_thumb" != "yes" ] && [ "$missing_marquee" != "yes" ]; then
        echo "   - Entry complete. Skipping."
        continue
    fi

    # 3. Get AppID from the local file
    real_file=$(echo "$game_path" | sed 's|^\./||')
    app_id=$(grep -oP '(?<=steam://rungameid/)\d+' "$real_file")
    
    if [ -z "$app_id" ]; then
        echo "   ! No AppID found in $real_file"
        continue
    fi

    # 4. SteamGridDB API Call
    search_res=$(curl -s -f -H "Authorization: Bearer $API_KEY" "https://www.steamgriddb.com/api/v2/games/steam/$app_id")
    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match on SteamGridDB for $game_path"
        continue
    fi

    # 5. Asset Fetcher
    fetch_asset() {
        local endpoint=$1 # grids, heroes, logos
        local tag=$2      # image, thumbnail, marquee
        local label=$3    # -image, -thumb, -marquee
        local is_missing=$4

        if [ "$is_missing" == "yes" ]; then
            url=$(curl -s -f -H "Authorization: Bearer $API_KEY" "https://www.steamgriddb.com/api/v2/$endpoint/game/$db_id" | grep -oP '(?<="url":")[^"]+' | head -n 1 | sed 's/\\//g')
            
            if [ -n "$url" ]; then
                ext="${url##*.}"
                ext="${ext%%\?*}" 
                game_prefix="${real_file%.*}"
                target_file="${IMG_DIR}/${game_prefix}${label}.${ext}"
                rel_path="./images/${game_prefix}${label}.${ext}"

                echo "   Downloading $tag..."
                curl -s -L -o "$target_file" "$url"
                
                if [ -s "$target_file" ]; then
                    update_xml_tag "$game_path" "$tag" "$rel_path"
                fi
            fi
        fi
    }

    fetch_asset "grids" "image" "-image" "$missing_image"
    fetch_asset "heroes" "thumbnail" "-thumb" "$missing_thumb"
    fetch_asset "logos" "marquee" "-marquee" "$missing_marquee"

done

echo "Done!"