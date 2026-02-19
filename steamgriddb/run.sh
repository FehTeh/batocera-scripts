#!/bin/bash

# 1. Config
API_KEY="$1"
ROM_DIR="/userdata/roms/steam"
IMG_DIR="${ROM_DIR}/images"

# 2. Validation
if [ -z "$API_KEY" ]; then
    echo "Usage: curl -L [url] | bash -s -- <api_key>"
    exit 1
fi

mkdir -p "$IMG_DIR"

# 3. Functions (Defined BEFORE the loop starts)
check_exists() {
    local prefix="$1"
    local label="$2"
    # Use find to be safe with spaces and different extensions
    count=$(find "$IMG_DIR" -maxdepth 1 -name "${prefix}${label}.*" | wc -l)
    echo "$count"
}

fetch() {
    local db_id=$1
    local endpoint=$2
    local label=$3
    local prefix=$4
    
    local exists=$(check_exists "$prefix" "$label")
    if [ "$exists" -gt 0 ]; then
        echo "   - $label exists. Skipping."
        return
    fi
    
    # Get and unescape URL
    url=$(curl -s -f -H "Authorization: Bearer $API_KEY" \
        "https://www.steamgriddb.com/api/v2/$endpoint/game/$db_id" | \
        grep -oP '(?<="url":")[^"]+' | head -n 1 | sed 's/\\//g')

    if [ -n "$url" ]; then
        ext="${url##*.}"
        ext="${ext%%\?*}" 
        target_file="${IMG_DIR}/${prefix}${label}.${ext}"
        
        echo "   Downloading from $url"
        curl -s -L -o "$target_file" "$url"
        
        if [ -s "$target_file" ]; then
            echo "   + Success: ${prefix}${label}.${ext}"
        else
            echo "   ! Download failed"
            rm -f "$target_file"
        fi
    fi
}

# 4. Main Logic
cd "$ROM_DIR" || exit

for file in *.steam; do
    [[ "$file" == "Steam.steam" ]] && continue
    [ -f "$file" ] || continue

    app_id=$(grep -oP '(?<=steam://rungameid/)\d+' "$file")
    [ -z "$app_id" ] && continue

    game_prefix="${file%.*}"
    
    # Check if we can skip the whole game
    has_img=$(check_exists "$game_prefix" "-image")
    has_thm=$(check_exists "$game_prefix" "-thumb")
    has_mrq=$(check_exists "$game_prefix" "-marquee")

    if [ "$has_img" -gt 0 ] && [ "$has_thm" -gt 0 ] && [ "$has_mrq" -gt 0 ]; then
        echo "--> Skipping $game_prefix: All assets exist."
        continue
    fi

    echo "Processing $game_prefix (AppID: $app_id)..."

    search_res=$(curl -s -f -H "Authorization: Bearer $API_KEY" \
        "https://www.steamgriddb.com/api/v2/games/steam/$app_id")
    db_id=$(echo "$search_res" | grep -oP '(?<="id":)\d+' | head -n 1)

    if [ -z "$db_id" ]; then
        echo "   X No match found."
        continue
    fi

    # Pass the required variables to the function
    fetch "$db_id" "grids" "-image" "$game_prefix"
    fetch "$db_id" "heroes" "-thumb" "$game_prefix"
    fetch "$db_id" "logos" "-marquee" "$game_prefix"
done

echo "Done!"