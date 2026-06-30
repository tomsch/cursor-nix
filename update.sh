#!/usr/bin/env bash
# Update script for cursor package
# Usage: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

# Resolve latest Linux x64 .deb through Cursor's updater endpoint.
# The old cursor.com/api/download endpoint now serves the marketing HTML page,
# which makes jq fail on GitHub runners.
echo "Resolving latest version..."
DOWNLOAD_ENDPOINT="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/stable"
DOWNLOAD_URL=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$DOWNLOAD_ENDPOINT")

if [[ ! "$DOWNLOAD_URL" =~ /production/[a-f0-9]{40}/.*/cursor_([0-9]+([.][0-9]+)+)_amd64[.]deb$ ]]; then
    echo "Unexpected Cursor download URL: $DOWNLOAD_URL" >&2
    exit 1
fi

LATEST_VERSION="${BASH_REMATCH[1]}"

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

# Update package.nix - final download URL
sed -i "s|url = \"[^\"]*downloads.cursor.com[^\"]*\";|url = \"$DOWNLOAD_URL\";|" "$PACKAGE_NIX"

echo "Updated package.nix to version $LATEST_VERSION"
