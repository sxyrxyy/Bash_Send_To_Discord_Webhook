#!/bin/bash

# Replace webhook
WEBHOOK_URL='https://discord.com/api/webhooks/1111111111111111111/xxxxxxxx_xxx_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

send_text() {
    local content="$1"
    # Use jq to safely encode JSON and handle special characters
    PAYLOAD=$(jq -nc --arg content "$content" '{
      username: "Big Bot",
      avatar_url: "https://sm.ign.com/t/ign_nordic/cover/a/avatar-gen/avatar-generations_prsz.300.jpg",
      embeds: [
        {
          title: "Notification",
          description: $content,
          color: 7419530,
          thumbnail: {
            url: "https://sm.ign.com/t/ign_nordic/cover/a/avatar-gen/avatar-generations_prsz.300.jpg"
          }
        }
      ]
    }')

    # Send the payload to the Discord webhook URL
    curl -X POST \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" \
      "$WEBHOOK_URL"
}

send_file() {
    local filepath="$1"
    local max_size=$((20 * 1024 * 1024)) # 20 MB in bytes
    local temp_dir="temp_split_dir"

    # Check if the file exists
    if [ ! -f "$filepath" ]; then
        echo "File does not exist: $filepath"
        return 1
    fi

    # Get file size in bytes
    local file_size=$(stat -c%s "$filepath")

    # Check if file size is within the limit
    if [ "$file_size" -le "$max_size" ]; then
        # If the file size is within the limit, send the file
        curl -s -X POST \
          -H "Content-Type: multipart/form-data" \
          -F "payload_json={\"username\": \"Big Bot\", \"avatar_url\": \"https://sm.ign.com/t/ign_nordic/cover/a/avatar-gen/avatar-generations_prsz.300.jpg\"}" \
          -F "file=@$filepath" \
          "$WEBHOOK_URL" > /dev/null 2>&1
    else
        # If the file is larger than the limit, split and send in chunks
        echo "File is larger than 20MB, splitting and sending in chunks..."
        mkdir -p "$temp_dir"
        filename=$(basename "$filepath")
        split -b "$max_size" "$filepath" "$temp_dir/${filename}_part_" --additional-suffix=.txt

        for file_chunk in "$temp_dir"/*; do
            echo "Sending chunk: $file_chunk"
            curl -s -X POST \
              -H "Content-Type: multipart/form-data" \
              -F "payload_json={\"username\": \"Big Bot\", \"avatar_url\": \"https://sm.ign.com/t/ign_nordic/cover/a/avatar-gen/avatar-generations_prsz.300.jpg\"}" \
              -F "file=@$file_chunk" \
              "$WEBHOOK_URL" > /dev/null 2>&1
        done

        # Clean up the temporary directory
        rm -rf "$temp_dir"
    fi
}

# Argument parsing
case "$1" in
    -text)
        send_text "$2"
        ;;
    -file)
        send_file "$2"
        ;;
    *)
        echo "Usage: $0 -text 'message' | -file /path/to/file"
        exit 1
        ;;
esac
