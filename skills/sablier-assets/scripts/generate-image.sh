#!/usr/bin/env bash
set -euo pipefail

# Generate an image using Gemini 2.5 Flash Image (Nano Banana)
# Usage: generate-image.sh "prompt" [output.png] [aspect_ratio]

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_dir="$script_dir/../output"

usage() {
    echo "Usage: $0 <prompt> [output_path] [aspect_ratio]" >&2
    echo "  prompt       - Text description for image generation" >&2
    echo "  output_path  - Path for generated PNG (default: output/<timestamp>.png)" >&2
    echo "  aspect_ratio - Optional: 1:1 (default), 16:9, 4:3, 9:16" >&2
    exit 1
}

[[ $# -lt 1 ]] && usage

prompt="$1"
output_path="${2:-$output_dir/$(date +%Y%m%d-%H%M%S).png}"
aspect_ratio="${3:-1:1}"

# Ensure output directory exists
mkdir -p "$(dirname "$output_path")"

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    echo "Error: GEMINI_API_KEY environment variable is not set" >&2
    exit 1
fi

# Validate aspect ratio (supported: 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9)
case "$aspect_ratio" in
    "1:1"|"2:3"|"3:2"|"3:4"|"4:3"|"4:5"|"5:4"|"9:16"|"16:9"|"21:9") ;;
    *) echo "Error: Invalid aspect ratio. Supported: 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9" >&2; exit 1 ;;
esac

# Build request payload
payload=$(jq -n \
    --arg prompt "$prompt" \
    --arg aspect "$aspect_ratio" \
    '{
        contents: [{
            parts: [{text: $prompt}]
        }],
        generationConfig: {
            responseModalities: ["TEXT", "IMAGE"],
            imageConfig: {
                aspectRatio: $aspect
            }
        }
    }')

echo "Generating image with aspect ratio $aspect_ratio..." >&2

# Call Gemini API
response=$(curl -s -X POST \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    --max-time 120)

# Check for API errors
if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
    error_message=$(echo "$response" | jq -r '.error.message')
    echo "Error: API request failed - $error_message" >&2
    exit 1
fi

# Extract base64 image data (response may have multiple parts: text and image)
image_data=$(echo "$response" | jq -r '.candidates[0].content.parts[] | select(.inlineData) | .inlineData.data // empty' | head -1)

if [[ -z "$image_data" ]]; then
    echo "Error: No image data in response" >&2
    echo "Response: $(echo "$response" | jq -c '.candidates[0].content.parts | map(keys)')" >&2
    exit 1
fi

# Decode and save image
echo "$image_data" | base64 -d > "$output_path"

if [[ -f "$output_path" ]]; then
    file_size=$(wc -c < "$output_path" | tr -d ' ')
    echo "Image saved to $output_path ($file_size bytes)" >&2
else
    echo "Error: Failed to save image" >&2
    exit 1
fi
