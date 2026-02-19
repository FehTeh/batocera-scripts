#!/bin/bash

API_KEY="$1"
ROM_DIR="/userdata/roms/steam"
IMG_DIR="${ROM_DIR}/images"
GAMELIST="${ROM_DIR}/gamelist.xml"

if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

mkdir -p "$IMG_DIR"

check_exists() {
    local prefix="$1"
    local label="$2"
    count=$(find "$IMG_DIR" -maxdepth 1 -name "${prefix}${label}.*" | wc -l)
    echo "$count"
}

# Function to update gamelist.xml
update_gamelist() {
    local game_file="./$1"
    local tag=$2    # image, marquee, or thumbnail
    local img_path=$3

    [ ! -f "$GAMELIST" ] && return

    # Check if the tag already exists for this specific game path
    # This looks for the block containing the game path and checks if the tag is inside it
    if ! grep -A 15 "<path>$game_file</path>" "$GAMELIST" | grep -q "<$tag>"; then
        echo "   * Adding <$tag> to gamelist.xml"
        # Standard sed trick: find the path line, then find the next </game> and insert before it
        # We use a temp file to be safe
        sed -i "/<path>$(echo "$game_file" | sed 's/\//\\\//g')<\/path>/,/<\/game>/ s/<\/game>/    <$tag>$img_path<\/$tag>\n        <\/game>/" "$GAMELIST"
    fi
}

fetch() {
    local db_id=$1
    local endpoint=$2
    local label=$3
    local prefix=$4
    local file_name=$5 # The full .steam filename
    
    # Map SteamGridDB labels to Gamelist tags
    local xml_tag="image"
    [[ "$label" == "-thumb" ]] && xml_tag="thumbnail"
    [[ "$label" == "-marquee" ]] && xml_tag="marquee"

    local url=$(curl -s -f -H "Authorization: Bearer $API_KEY" \
        "https://www.steamgriddb.com/api/v2/$endpoint/game/$db_id" | \
        grep -oP '(?<="url":")[^"]+' | head -n 1 | sed 's/\\//g')

    if [ -n "$url" ]; then
        ext="${url##*.}"
        ext="${ext%%\?*}" 
        target_file="${IMG_DIR}/${prefix}${label}.${ext}"
        relative_path="./images/${prefix}${label}.${ext}"
        
        if [ ! -s "$target_file" ]; then
            echo "   Downloading $label..."
            curl -s -L -o "$target_file" "$url"
        fi

        if [ -s "$target_file" ]; then
            update_gamelist "$file_name" "$xml_tag" "$relative_path"
        fi
    fi
}

cd "$ROM_DIR" || exit

for file in *.steam; do
    [[ "$file" == "Steam.steam" ]] && continue
    [ -f "$file" ] || continue

    app_id=$(grep -oP '(?<=steam://rungameid/)\d+' "$file")
    [ -z "$app_id" ] && continue

    game_prefix="${file%.*}"
    echo "Processing $game_prefix..."

    search_res=$(curl -s -f -H "Authorization: Bearer $API_KEY" \
        "https://www.steamgriddb.com/api/v2/games/steam/$app_id")
    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match found."
        continue
    fi

    fetch "$db_id" "grids" "-image" "$game_prefix" "$file"
    fetch "$db_id" "heroes" "-thumb" "$game_prefix" "$file"
    fetch "$db_id" "logos" "-marquee" "$game_prefix" "$file"
done

echo "Done! Please refresh your gamelist in Batocera."