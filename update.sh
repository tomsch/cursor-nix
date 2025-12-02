#!/usr/bin/env bash
# Update script for cursor package
# Usage: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

# Get latest version from Cursor API
echo "Fetching latest version..."
API_RESPONSE=$(curl -sL "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable")
LATEST_VERSION=$(echo "$API_RESPONSE" | jq -r '.version')
DOWNLOAD_URL=$(echo "$API_RESPONSE" | jq -r '.debUrl')
COMMIT_SHA=$(echo "$API_RESPONSE" | jq -r '.commitSha')

# Get current version from package.nix
CURRENT_VERSION=$(grep 'version = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already up to date!"
    exit 0
fi

# Fetch new hash
echo "Fetching hash for $LATEST_VERSION..."
NEW_HASH=$(nix-prefetch-url "$DOWNLOAD_URL" 2>&1 | tail -1)
SRI_HASH=$(nix hash convert --to sri --hash-algo sha256 "$NEW_HASH")

echo "New SRI hash: $SRI_HASH"

# Update package.nix - version
sed -i "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$PACKAGE_NIX"

# Update package.nix - hash
sed -i "s|hash = \"sha256-.*\"|hash = \"$SRI_HASH\"|" "$PACKAGE_NIX"

# Update package.nix - commit SHA in URL
OLD_SHA=$(grep -oP 'production/\K[a-f0-9]{40}' "$PACKAGE_NIX" | head -1)
sed -i "s|$OLD_SHA|$COMMIT_SHA|" "$PACKAGE_NIX"

echo "Updated package.nix to version $LATEST_VERSION"
