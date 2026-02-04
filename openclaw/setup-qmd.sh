#!/bin/sh
set -e

# setup-qmd.sh — Install and configure QMD (local search sidecar) for OpenClaw
# QMD provides BM25 + vector search + LLM reranking for workspace memory
# https://github.com/tobi/qmd
#
# Usage: sh /opt/openclaw/setup-qmd.sh
# Safe to run multiple times (idempotent).

echo "=== QMD Setup ==="

# --- Config variables ---
BUN_DIR="$HOME/.bun"
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
CONFIG_FILE="$STATE_DIR/openclaw.json"
QMD_STATE_DIR="$STATE_DIR/agents/main/qmd"
XDG_CONFIG_DIR="$QMD_STATE_DIR/xdg-config"
XDG_CACHE_DIR="$QMD_STATE_DIR/xdg-cache"

# --- 1. Install Bun (if not present) ---
if command -v bun >/dev/null 2>&1; then
  echo "Bun already installed: $(bun --version)"
else
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$BUN_DIR/bin:$PATH"
  echo "Bun installed: $(bun --version)"
fi

# Ensure bun is on PATH for the rest of this script
export PATH="$BUN_DIR/bin:$PATH"

# --- 2. Install QMD (if not present) ---
if command -v qmd >/dev/null 2>&1; then
  echo "QMD already installed"
else
  echo "Installing QMD..."
  bun install -g github:tobi/qmd
  echo "QMD installed"
fi

# Verify QMD is available
if ! command -v qmd >/dev/null 2>&1; then
  echo "Error: QMD installation failed — 'qmd' not found on PATH"
  exit 1
fi

# --- 3. Set up XDG directories ---
mkdir -p "$XDG_CONFIG_DIR" "$XDG_CACHE_DIR"
export XDG_CONFIG_HOME="$XDG_CONFIG_DIR"
export XDG_CACHE_HOME="$XDG_CACHE_DIR"

# --- 4. Create collection for workspace memory ---
echo "Setting up QMD collection for workspace memory..."
qmd collection add "$WORKSPACE_DIR" --name memory-root || true

# --- 5. Build index ---
echo "Updating QMD index..."
qmd update || true

echo "Building QMD embeddings (downloads ~2GB of models on first run)..."
qmd embed || true

# --- 6. Add QMD config to openclaw.json (if not already configured) ---
if [ -f "$CONFIG_FILE" ]; then
  node -e "
    const fs = require('fs');
    const configPath = '$CONFIG_FILE';

    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

      if (config.memory?.backend === 'qmd') {
        console.log('QMD memory backend already configured.');
        process.exit(0);
      }

      console.log('Adding QMD memory backend config...');

      config.memory = Object.assign(config.memory || {}, {
        backend: 'qmd',
        citations: 'auto',
        qmd: {
          includeDefaultMemory: true,
          update: {
            interval: '5m',
            onBoot: true,
            embedInterval: '5m'
          },
          limits: {
            maxResults: 6,
            maxSnippetChars: 700,
            maxInjectedChars: 4000,
            timeoutMs: 4000
          }
        }
      });

      fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
      console.log('QMD memory backend added to openclaw.json');
    } catch (err) {
      console.error('Warning: Failed to update config for QMD:', err.message);
      console.error('You may need to configure the memory backend manually.');
    }
  " || true
else
  echo "Warning: $CONFIG_FILE not found — skipping config update."
  echo "Run startup.sh first or configure memory.backend manually."
fi

echo ""
echo "=== QMD Setup Complete ==="
echo "QMD state: $QMD_STATE_DIR"
echo "SQLite index: $XDG_CACHE_DIR/qmd/index.sqlite"
echo ""
echo "To verify: XDG_CONFIG_HOME=$XDG_CONFIG_DIR XDG_CACHE_HOME=$XDG_CACHE_DIR qmd status"
