#!/bin/bash
set -e

err() { echo "Error: $1 installation failed" >&2; exit 1; }

# APT packages
apt-get update -qq 2>/dev/null
apt-get install -qq -y \
  tree jq ripgrep sqlite3 fd-find html2text pdfgrep \
  binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 \
  libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 \
  libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata \
  zip unzip zlib1g-dev >/dev/null 2>&1 || err "apt packages"

# yq
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 || err "yq"
chmod +x /usr/local/bin/yq

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs 2>/dev/null | sh -s -- -y >/dev/null 2>&1 || true
. "$HOME/.cargo/env" 2>/dev/null || true

# fclones
if command -v cargo >/dev/null 2>&1; then
  cargo install fclones -q 2>/dev/null || err "fclones"
fi

# Swift
SWIFT_VERSION="6.2.2"
SWIFT_FILE="swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04.tar.gz"
SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2404/swift-${SWIFT_VERSION}-RELEASE/${SWIFT_FILE}"

cd /tmp
wget -q "$SWIFT_URL" || err "Swift download"
tar xzf "$SWIFT_FILE" >/dev/null 2>&1 || err "Swift extract"
rm -rf /opt/swift 2>/dev/null
mv "swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04" /opt/swift || err "Swift install"
ln -sf /opt/swift/usr/bin/swift /usr/local/bin/swift
ln -sf /opt/swift/usr/bin/swiftc /usr/local/bin/swiftc
rm -f "$SWIFT_FILE"
