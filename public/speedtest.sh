#!/usr/bin/env bash
# speedtest.sh — Download and run the Speedtest.net CLI on Linux or macOS.
# Usage: bash speedtest.sh [speedtest-cli-args...]
#   e.g. curl -sL asheroto.com/speedtest-linux | bash
#   e.g. curl -sL asheroto.com/speedtest-linux | bash -s -- --servers

set -euo pipefail

# ── Platform detection ────────────────────────────────────────────────────────

detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "macos" ;;
        *)       echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)   echo "x86_64" ;;
        aarch64|arm64)  echo "aarch64" ;;
        *)              echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac
}

# ── Dependency check ──────────────────────────────────────────────────────────

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: '$1' is required but not installed." >&2
        exit 1
    fi
}

require_cmd curl
require_cmd tar

# ── Download link scraping ────────────────────────────────────────────────────

get_download_link() {
    local os="$1"
    local arch="$2"
    local page
    page=$(curl -fsSL "https://www.speedtest.net/apps/cli")

    if [[ "$os" == "linux" ]]; then
        # Try exact arch first, fall back to x86_64
        local link
        link=$(echo "$page" | grep -oE 'https://install\.speedtest\.net/app/cli/ookla-speedtest-[0-9.]+-linux-'"$arch"'\.tgz' | head -1)
        if [[ -z "$link" && "$arch" != "x86_64" ]]; then
            echo "Warning: no $arch build found, falling back to x86_64." >&2
            link=$(echo "$page" | grep -oE 'https://install\.speedtest\.net/app/cli/ookla-speedtest-[0-9.]+-linux-x86_64\.tgz' | head -1)
        fi
        echo "$link"
    elif [[ "$os" == "macos" ]]; then
        local link=""
        # Try ARM64-specific build first for Apple Silicon
        if [[ "$arch" == "aarch64" ]]; then
            link=$(echo "$page" | grep -oE 'https://install\.speedtest\.net/app/cli/ookla-speedtest-[0-9.]+-(macosx|macos|darwin|apple)-[a-zA-Z0-9_-]*(arm64|aarch64)[a-zA-Z0-9_-]*\.tgz' | head -1)
        fi
        # Fall back to any macOS build (universal, x86_64, or however Ookla names it)
        if [[ -z "$link" ]]; then
            link=$(echo "$page" | grep -oE 'https://install\.speedtest\.net/app/cli/ookla-speedtest-[0-9.]+-(macosx|macos|darwin|apple)[a-zA-Z0-9._-]*\.tgz' | head -1)
        fi
        echo "$link"
    fi
}

# ── Cleanup helper ────────────────────────────────────────────────────────────

cleanup() {
    [[ -n "${ARCHIVE_PATH:-}" && -f "$ARCHIVE_PATH" ]] && rm -f "$ARCHIVE_PATH"
    [[ -n "${EXTRACT_DIR:-}" && -d "$EXTRACT_DIR" ]] && rm -rf "$EXTRACT_DIR"
}
trap cleanup EXIT

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    local os arch tmp link

    os=$(detect_os)
    arch=$(detect_arch)
    tmp="${TMPDIR:-/tmp}"
    tmp="${tmp%/}"  # strip trailing slash

    echo "Detected platform: $os ($arch)"

    link=$(get_download_link "$os" "$arch")
    if [[ -z "$link" ]]; then
        echo "Error: could not find a download link for $os ($arch)." >&2
        exit 1
    fi

    ARCHIVE_PATH="$tmp/speedtest-$os-$arch.tgz"
    EXTRACT_DIR="$tmp/speedtest-$os-$arch"

    # Clean up any leftover files from a previous run
    rm -f "$ARCHIVE_PATH"
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"

    echo "Downloading Speedtest CLI..."
    curl -fsSL "$link" -o "$ARCHIVE_PATH"

    echo "Extracting archive..."
    tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR"

    local exe="$EXTRACT_DIR/speedtest"
    chmod +x "$exe"

    echo "Running Speedtest..."
    "$exe" --accept-license --accept-gdpr "$@"

    echo "Cleaning up..."
    # cleanup() runs automatically via trap
}

main "$@"
