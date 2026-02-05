#!/usr/bin/env bash
set -euo pipefail

# Validate GEMINI_API_KEY environment variable and API connectivity

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    echo "Error: GEMINI_API_KEY environment variable is not set" >&2
    echo "Get your API key at: https://aistudio.google.com/apikey" >&2
    exit 1
fi

# Test API connectivity with a minimal request
response=$(curl -s -w "\n%{http_code}" \
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [[ "$http_code" == "200" ]]; then
    echo "Gemini API key is valid and model is accessible"
    exit 0
elif [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
    echo "Error: Invalid or unauthorized API key" >&2
    exit 1
elif [[ "$http_code" == "404" ]]; then
    echo "Error: Model gemini-2.5-flash-image not found or not accessible" >&2
    exit 1
else
    echo "Error: Unexpected response (HTTP $http_code)" >&2
    echo "$body" >&2
    exit 1
fi
