#!/bin/bash

API_KEY="$1"
ROM_DIR="/userdata/roms/steam"
IMG_DIR="${ROM_DIR}/images"
GAMELIST="${ROM_DIR}/gamelist.xml"

if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

[ ! -f "$GAMELIST" ] && echo "Error: gamelist.xml not found in $ROM_DIR" && exit 1

mkdir -p "$IMG_DIR"
cd "$ROM_DIR" || exit

# Function to update gamelist.xml for a specific tag
update_xml_tag() {
    local game_path=$1
    local tag=$2
    local img_path=$3
    
    echo "   * Adding <$tag> to gamelist.xml"
    # Escaping path for sed
    local escaped_path=$(echo "$game_path" | sed 's/[^^]/[&]/g; s/\^/\\^/g')
    sed -i "/<path>${escaped_path}<\/path>/,/<\/game>/ s/<\/game>/    <$tag>$img_path<\/$tag>\n        <\/game>/" "$GAMELIST"
}

# --- Main Logic ---

# 1. Get a list of all <game> blocks from gamelist.xml
# We use a temporary file to store the paths of games that need checking
grep -oP '(?<=<path>).*?(?=</path>)' "$GAMELIST" | while read -r game_path; do
    
    # Only process .steam files
    [[ "$game_path" != *".steam" ]] && continue
    [[ "$game_path" == *"Steam.steam" ]] && continue

    # 2. Check if this specific game block is missing any tags
    # We grab the block (approx 20 lines) and check for tags
    game_block=$(grep -A 20 "<path>$game_path</path>" "$GAMELIST")
    
    missing_image=$(echo "$game_block" | grep -q "<image>" || echo "yes")
    missing_thumb=$(echo "$game_block" | grep -q "<thumbnail>" || echo "yes")
    missing_marquee=$(echo "$game_block" | grep -q "<marquee>" || echo "yes")

    if [ "$missing_image" != "yes" ] && [ "$missing_thumb" != "yes" ] && [ "$missing_marquee" != "yes" ]; then
        continue
    fi

    # 3. Resolve actual filename and AppID
    # game_path is usually ./Name.steam, we need the real file to get the ID
    real_file=$(echo "$game_path" | sed 's|^\./||')
    if [ ! -f "$real_file" ]; then continue; fi
    
    app_id=$(grep -oP '(?<=steam://rungameid/)\d+' "$real_file")
    [ -z "$app_id" ] && continue

    game_prefix="${real_file%.*}"
    echo "Incomplete entry found: $game_prefix (AppID: $app_id)"

    # 4. Fetch SteamGridDB ID
    search_res=$(curl -s -f -H "Authorization: Bearer $API_KEY" "https://www.steamgriddb.com/api/v2/games/steam/$app_id")
    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match on SteamGridDB"
        continue
    fi

    # 5. Internal Download Helper
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

echo "Done! Restart EmulationStation to see changes."