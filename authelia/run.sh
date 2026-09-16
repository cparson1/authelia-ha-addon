#!/bin/sh
# HA add-on entrypoint wrapper for Authelia.
#
# Seeds default config/users files and randomly-generated secrets into the
# add-on's Supervisor-managed persistent /data folder on first run (so they
# survive rebuilds/updates), then hands off to Authelia's own entrypoint.
set -eu

echo "[run.sh] preparing persistent data directories"
mkdir -p /data/config /data/secrets /data/db /data/notifications

if [ ! -f /data/config/configuration.yml ]; then
    echo "[run.sh] seeding default configuration.yml"
    cp /defaults/configuration.yml /data/config/configuration.yml
fi

if [ ! -f /data/config/users_database.yml ]; then
    echo "[run.sh] seeding default users_database.yml"
    cp /defaults/users_database.yml /data/config/users_database.yml
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

generate_secret_file /data/secrets/jwt_secret
generate_secret_file /data/secrets/session_secret
generate_secret_file /data/secrets/storage_encryption_key

echo "[run.sh] handing off to /app/entrypoint.sh"

export X_AUTHELIA_CONFIG=/data/config/configuration.yml
export AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE=/data/secrets/jwt_secret
export AUTHELIA_SESSION_SECRET_FILE=/data/secrets/session_secret
export AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE=/data/secrets/storage_encryption_key

exec /app/entrypoint.sh "$@"
