#!/bin/sh
set -e

# setup-tailscale.sh — Install and configure Tailscale for OpenClaw
# Enables HTTPS access via Tailscale + MagicDNS with OpenClaw's built-in
# Tailscale Serve integration (gateway --tailscale serve).
#
# This script only installs Tailscale and authenticates.
# OpenClaw gateway handles `tailscale serve` itself.
#
# Usage: sh /opt/openclaw/setup-tailscale.sh
# Safe to run multiple times (idempotent).
#
# Environment variables:
#   TS_AUTHKEY   (required)  Tailscale auth key. Script skips if unset.
#                            Get one at: https://login.tailscale.com/admin/settings/keys
#   TS_VERSION   (optional)  Tailscale version to install. Default: 1.82.5
#   TS_HOSTNAME  (optional)  Hostname on tailnet. Default: openclaw

echo "=== Tailscale Setup ==="

# --- Config variables ---
TS_VERSION="${TS_VERSION:-1.82.5}"
TS_HOSTNAME="${TS_HOSTNAME:-openclaw}"
BIN_DIR="$HOME/bin"
STATE_DIR="$HOME/.tailscale/state"
SOCK="$HOME/.tailscale/tailscaled.sock"
LOG="$HOME/.tailscale/tailscaled.log"

# --- 0. Check TS_AUTHKEY ---
if [ -z "$TS_AUTHKEY" ]; then
  echo "TS_AUTHKEY not set — skipping Tailscale setup."
  echo "Set TS_AUTHKEY to a Tailscale auth key to enable."
  echo "Get one at: https://login.tailscale.com/admin/settings/keys"
  exit 0
fi

# --- 1. Detect architecture ---
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  TS_ARCH="amd64" ;;
  aarch64) TS_ARCH="arm64" ;;
  arm64)   TS_ARCH="arm64" ;;
  *)
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac
echo "Architecture: $ARCH ($TS_ARCH)"

# --- 2. Install Tailscale binaries ---
INSTALLED_VERSION=""
if [ -x "$BIN_DIR/tailscale" ]; then
  INSTALLED_VERSION="$("$BIN_DIR/tailscale" version 2>/dev/null | head -1 || true)"
fi

if [ "$INSTALLED_VERSION" = "$TS_VERSION" ]; then
  echo "Tailscale $TS_VERSION already installed."
else
  echo "Installing Tailscale $TS_VERSION..."
  TARBALL="tailscale_${TS_VERSION}_${TS_ARCH}.tgz"
  URL="https://pkgs.tailscale.com/stable/${TARBALL}"
  TMPDIR="$(mktemp -d)"

  curl -fsSL "$URL" -o "$TMPDIR/$TARBALL"
  tar -xzf "$TMPDIR/$TARBALL" -C "$TMPDIR"

  mkdir -p "$BIN_DIR"
  cp "$TMPDIR/tailscale_${TS_VERSION}_${TS_ARCH}/tailscale" "$BIN_DIR/tailscale"
  cp "$TMPDIR/tailscale_${TS_VERSION}_${TS_ARCH}/tailscaled" "$BIN_DIR/tailscaled"
  chmod +x "$BIN_DIR/tailscale" "$BIN_DIR/tailscaled"

  rm -rf "$TMPDIR"
  echo "Tailscale $TS_VERSION installed to $BIN_DIR"
fi

# --- 3. Start tailscaled ---
mkdir -p "$HOME/.tailscale/state"

# Check if tailscaled is already running
if [ -S "$SOCK" ] && "$BIN_DIR/tailscale" --socket="$SOCK" status >/dev/null 2>&1; then
  echo "tailscaled already running."
else
  echo "Starting tailscaled..."

  # Kill any stale tailscaled process
  if [ -f "$HOME/.tailscale/tailscaled.pid" ]; then
    OLD_PID="$(cat "$HOME/.tailscale/tailscaled.pid")"
    kill "$OLD_PID" 2>/dev/null || true
    sleep 1
  fi

  # Remove stale socket
  rm -f "$SOCK"

  "$BIN_DIR/tailscaled" \
    --tun=userspace-networking \
    --statedir="$STATE_DIR" \
    --socket="$SOCK" \
    >"$LOG" 2>&1 &

  TAILSCALED_PID=$!
  echo "$TAILSCALED_PID" > "$HOME/.tailscale/tailscaled.pid"
  echo "tailscaled started (PID $TAILSCALED_PID)"

  # Wait for socket to be ready
  echo "Waiting for tailscaled socket..."
  WAIT=0
  while [ ! -S "$SOCK" ]; do
    sleep 1
    WAIT=$((WAIT + 1))
    if [ "$WAIT" -ge 30 ]; then
      echo "Error: tailscaled socket not ready after 30s"
      echo "Check logs: $LOG"
      exit 1
    fi
  done
  echo "tailscaled socket ready."
fi

# --- 4. Authenticate ---
BACKEND_STATE="$("$BIN_DIR/tailscale" --socket="$SOCK" status --json 2>/dev/null | node -e "
  let d = '';
  process.stdin.on('data', c => d += c);
  process.stdin.on('end', () => {
    try { console.log(JSON.parse(d).BackendState); }
    catch(e) { console.log('Unknown'); }
  });
" 2>/dev/null || echo "Unknown")"

if [ "$BACKEND_STATE" = "Running" ]; then
  echo "Tailscale already authenticated."
else
  echo "Authenticating with Tailscale..."
  "$BIN_DIR/tailscale" --socket="$SOCK" up \
    --authkey="$TS_AUTHKEY" \
    --hostname="$TS_HOSTNAME"
  echo "Tailscale authenticated."
fi

# --- 5. Print status ---
echo ""
echo "=== Tailscale Setup Complete ==="
"$BIN_DIR/tailscale" --socket="$SOCK" status || true
echo ""
echo "Tailscale state: $STATE_DIR"
echo "Daemon log:      $LOG"
echo "Socket:          $SOCK"
echo ""
echo "Next steps (Phase 2):"
echo "  Modify start_gateway.sh to use: gateway --tailscale serve"
echo "  Then access OpenClaw at: https://${TS_HOSTNAME}.<your-tailnet>.ts.net"
