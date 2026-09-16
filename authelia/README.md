# Authelia (Home Assistant add-on)

Wraps the official `authelia/authelia:4.39.27` image as a local HA add-on,
with persistent config/secrets on the add-on's own `/data` volume.

## Install

1. Add this repo in HA: Settings → Add-ons → Add-on Store → ⋮ → Repositories
   → `https://github.com/cparson1/authelia-ha-addon`
2. Install the "Authelia" add-on, start it.
3. Open the web UI button (or `http://<ha-host>:9091`) - you should see the
   Authelia login page. Login will fail until you add a real user (next
   step) since the seeded default user is disabled.

## Add yourself as a user

The default `/data/config/users_database.yml` has one disabled placeholder
user. To add yourself:

1. Generate a password hash (needs Docker somewhere - doesn't have to be
   the HA box):
   ```
   docker run --rm authelia/authelia:4.39.27 authelia crypto hash generate argon2 --password 'your-real-password'
   ```
2. Edit `/data/config/users_database.yml` on the HA box (Samba share add-on,
   path depends on how Supervisor exposes add-on data folders - check the
   Authelia add-on's info page, or browse via the Samba/File editor add-on)
   and replace the placeholder user with your own username, the generated
   hash, your email, and `disabled: false`.
3. Restart the Authelia add-on.

## What this protects, and how

Authelia doesn't sit in the request path by itself - NPM (or whatever
reverse proxy sits in front of your apps) asks Authelia "is this request
authenticated?" via a forward-auth check, and only proxies through if the
answer is yes. See the main NPM setup notes (outside this repo) for the
`auth_request` snippet that wires this up per proxy host.

`/data/config/configuration.yml` assumes your domain is `parcelisk.net`
and the login portal is `auth.parcelisk.net` - edit both the config and
your NPM/Cloudflare setup consistently if you use something else.

## Persistent data

`/data/config` (configuration.yml, users_database.yml), `/data/secrets`
(randomly-generated JWT/session/storage-encryption secrets, created on
first run), `/data/db` (SQLite session/regulation storage), and
`/data/notifications` (password-reset "emails" written to a file, since
no SMTP is configured by default) all live on the add-on's
Supervisor-managed persistent volume - survives rebuilds, included in HA
backups.

## Updating

Bump `version:` in `config.yaml` and push to pick up a newer Authelia
release - edit the `FROM authelia/authelia:X.Y.Z` line in `Dockerfile`
first. Check https://hub.docker.com/r/authelia/authelia/tags for current
stable tags.
