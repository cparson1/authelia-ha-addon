#!/bin/sh
# HA add-on entrypoint wrapper for Authelia.
#
# Seeds default config/users files and randomly-generated secrets into
# /config on first run. /config is the externally-visible persistent
# folder for this add-on (via the "addon_config" map option in
# config.yaml, surfaced under /addon_configs/<slug> on the host and via
# Samba) - NOT the same as /data, which is always mounted internally but
# never exposed externally. Using /config is what lets you actually
# hand-edit configuration.yml/users_database.yml after install.
set -eu

echo "[run.sh] preparing persistent config directory"
mkdir -p /config/secrets /config/db /config/notifications

if [ ! -f /config/configuration.yml ]; then
    echo "[run.sh] seeding default configuration.yml"
    cp /defaults/configuration.yml /config/configuration.yml
fi

if [ ! -f /config/users_database.yml ]; then
    echo "[run.sh] seeding default users_database.yml"
    cp /defaults/users_database.yml /config/users_database.yml
fi

generate_secret_file() {
    file="$1"
    if [ -f "$file" ] && [ -s "$file" ]; then
        return 0
    fi
    echo "[run.sh] generating secret: $file"
    # Avoids depending on a `base64` binary, which isn't guaranteed to
    # exist in Authelia's base image. tr/head are universally available.
    head -c 128 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 64 > "$file"
    if [ ! -s "$file" ]; then
        echo "[run.sh] FATAL: failed to generate non-empty secret at $file" >&2
        exit 1
    fi
}

generate_secret_file /config/secrets/jwt_secret
generate_secret_file /config/secrets/session_secret
generate_secret_file /config/secrets/storage_encryption_key

echo "[run.sh] handing off to /app/entrypoint.sh"

export X_AUTHELIA_CONFIG=/config/configuration.yml
export AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE=/config/secrets/jwt_secret
export AUTHELIA_SESSION_SECRET_FILE=/config/secrets/session_secret
export AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE=/config/secrets/storage_encryption_key

exec /app/entrypoint.sh "$@"
