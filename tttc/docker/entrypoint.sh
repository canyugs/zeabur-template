#!/bin/sh
set -e

# Replace build-time Firebase placeholders with runtime environment variables
# This allows NEXT_PUBLIC_* values to be configured via env vars without rebuilding

replace_placeholder() {
  local placeholder="$1"
  local env_value="$2"
  if [ -n "$env_value" ] && [ "$env_value" != "$placeholder" ]; then
    find /app/next-client/.next -name '*.js' -exec sed -i "s|${placeholder}|${env_value}|g" {} + 2>/dev/null || true
    find /app/next-client/.next -name '*.html' -exec sed -i "s|${placeholder}|${env_value}|g" {} + 2>/dev/null || true
  fi
}

echo "[entrypoint] Injecting Firebase config from environment variables..."

replace_placeholder "__FIREBASE_API_KEY_PLACEHOLDER__" "$NEXT_PUBLIC_FIREBASE_API_KEY"
replace_placeholder "__FIREBASE_AUTH_DOMAIN_PLACEHOLDER__" "$NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN"
replace_placeholder "__FIREBASE_PROJECT_ID_PLACEHOLDER__" "$NEXT_PUBLIC_FIREBASE_PROJECT_ID"
replace_placeholder "__FIREBASE_STORAGE_BUCKET_PLACEHOLDER__" "$NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET"
replace_placeholder "__FIREBASE_MESSAGING_SENDER_ID_PLACEHOLDER__" "$NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID"
replace_placeholder "__FIREBASE_APP_ID_PLACEHOLDER__" "$NEXT_PUBLIC_FIREBASE_APP_ID"

echo "[entrypoint] Firebase config injection complete, starting server..."

exec node server.js
