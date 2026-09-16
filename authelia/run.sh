#!/bin/sh
# HA add-on entrypoint wrapper for Authelia.
#
# Seeds default config/users files and randomly-generated secrets into the
# add-on's Supervisor-managed persistent /data folder on first run (so they
# survive rebuilds/updates), then hands off to Authelia's own entrypoint.
set -e

mkdir -p /data/config /data/secrets /data/db /data/notifications

if [ ! -f /data/config/configuration.yml ]; then
    cp /defaults/configuration.yml /data/config/configuration.yml
fi

if [ ! -f /data/config/users_database.yml ]; then
    cp /defaults/users_database.yml /data/config/users_database.yml
fi

generate_secret_file() {
    file="$1"
    if [ ! -f "$file" ]; then
        head -c 64 /dev/urandom | base64 | tr -d '\n=+/' | head -c 64 > "$file"
    fi
}

generate_secret_file /data/secrets/jwt_secret
generate_secret_file /data/secrets/session_secret
generate_secret_file /data/secrets/storage_encryption_key

export X_AUTHELIA_CONFIG=/data/config/configuration.yml
export AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE=/data/secrets/jwt_secret
export AUTHELIA_SESSION_SECRET_FILE=/data/secrets/session_secret
export AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE=/data/secrets/storage_encryption_key

exec /app/entrypoint.sh "$@"
