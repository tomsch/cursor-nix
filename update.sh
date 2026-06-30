#!/usr/bin/env bash
# Update script for cursor GUI and cursor-cli packages
# Usage: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"
PACKAGE_CLI_NIX="$SCRIPT_DIR/package-cli.nix"

prefetch_sri() {
    local url="$1"
    local hash
    local sri_hash

    hash=$(nix-prefetch-url "$url" 2>&1 | tail -1)
    sri_hash=$(nix hash convert --to sri --hash-algo sha256 "$hash")

    if [[ ! "$sri_hash" =~ ^sha256- ]]; then
        echo "Invalid SRI hash for $url: $sri_hash" >&2
        exit 1
    fi

    printf '%s\n' "$sri_hash"
}

update_gui() {
    echo "=== Checking cursor GUI ==="

    local download_endpoint="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/stable"
    local download_url
    download_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$download_endpoint")

    if [[ ! "$download_url" =~ /production/[a-f0-9]{40}/.*/cursor_([0-9]+([.][0-9]+)+)_amd64[.]deb$ ]]; then
        echo "Unexpected Cursor download URL: $download_url" >&2
        exit 1
    fi

    local latest_version="${BASH_REMATCH[1]}"
    local current_version
    current_version=$(grep 'version = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

    echo "Current version: $current_version"
    echo "Latest version:  $latest_version"

    if [ "$current_version" = "$latest_version" ]; then
        echo "GUI already up to date."
        return 0
    fi

    echo "Fetching GUI hash for $latest_version..."
    local sri_hash
    sri_hash=$(prefetch_sri "$download_url")
    echo "New GUI SRI hash: $sri_hash"

    sed -i "s/version = \"$current_version\"/version = \"$latest_version\"/" "$PACKAGE_NIX"
    sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$sri_hash\"|" "$PACKAGE_NIX"
    sed -i "s|url = \"[^\"]*downloads.cursor.com[^\"]*\";|url = \"$download_url\";|" "$PACKAGE_NIX"

    echo "Updated package.nix to version $latest_version"
}

update_cli() {
    echo "=== Checking cursor-cli ==="

    local latest_version
    latest_version=$(curl -fsSL https://cursor.com/install \
        | grep -oP 'lab/\K[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[^/]+' \
        | head -1)

    if [ -z "$latest_version" ]; then
        echo "Error: Could not parse latest version from cursor.com/install" >&2
        echo "       (script format may have changed - check the regex)" >&2
        exit 1
    fi

    local download_url="https://downloads.cursor.com/lab/${latest_version}/linux/x64/agent-cli-package.tar.gz"
    local current_version
    current_version=$(grep 'version = ' "$PACKAGE_CLI_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

    echo "Current version: $current_version"
    echo "Latest version:  $latest_version"

    if [ "$current_version" = "$latest_version" ]; then
        echo "CLI already up to date."
        return 0
    fi

    echo "Fetching CLI hash for $latest_version..."
    local sri_hash
    sri_hash=$(prefetch_sri "$download_url")
    echo "New CLI SRI hash: $sri_hash"

    sed -i "s/version = \"$current_version\"/version = \"$latest_version\"/" "$PACKAGE_CLI_NIX"
    sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$sri_hash\"|" "$PACKAGE_CLI_NIX"

    echo "Updated package-cli.nix to version $latest_version"
}

update_gui
update_cli
