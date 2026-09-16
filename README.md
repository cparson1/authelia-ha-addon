# cparson1's Authelia Add-on

A Home Assistant custom add-on repository. Add it in Home Assistant via
Settings → Add-ons → Add-on Store → ⋮ (top right) → Repositories → paste:

```
https://github.com/cparson1/authelia-ha-addon
```

## Add-ons in this repository

- **[authelia](./authelia/)** — SSO / forward-auth portal for apps proxied
  through NPM (or any reverse proxy that supports `auth_request`/forward
  auth). Kept as its own repo, separate from any single app it protects,
  since it's infrastructure meant to serve multiple apps over time.
