# Cronometer bridge

Status: prepared files only. No image built, service deployed, or public access
configured. Upstream's 72 offline tests passed; live Cronometer and ChatGPT
behavior have not been tested.

One container runs the upstream backend and authenticated OAuth gateway. The
backend stays on container localhost:8430. The gateway listens on container
port 8432, published only at host `127.0.0.1:8431`. No nginx is needed.
Supervisor manages both processes using `supervisord.conf`, restarting them
independently after runtime exits. Docker restarts the container after a host
reboot or container exit. Repeated startup failures eventually stop retries;
health checks report failure but do not themselves restart the container.
There is no custom process launcher.

The Dockerfile pins upstream revision
`e123a4721093efa55adac665e10a546c105eb117`. Two small source adjustments make the gateway reachable through Docker's
loopback port mapping and disable dotenv interpolation so password characters
are preserved literally. Both adjustments fail the build if upstream changes. Authentication stays enabled. Base images and Python dependencies
still need reproducible locks during the build stage.

Ansible deployment is in `ansible/roles/applications/tasks/cronometer.yml`.
It requires manually configured Vault secrets, prepares private runtime files
and directories, copies the project, and runs Compose. Changed project files trigger a rebuild.
Check mode previews file changes and skips Compose; it cannot validate a build.
The role does not configure Funnel, prompt for secrets, or generate passwords.

The bridge is disabled by default. Once Vault configuration is complete,
set these values in host inventory so normal `make apply` deploys it:

```yaml
cronometer_enabled: true
cronometer_username: YOUR_CRONOMETER_EMAIL
cronometer_public_url: https://YOUR_PUBLIC_HOST
```

Run `make vault-edit` and manually add these values alongside the
existing Samba secrets:

```yaml
vault_cronometer_password:
  "YOUR_CRONOMETER_EMAIL": "YOUR_CRONOMETER_PASSWORD"
vault_cronometer_bridge_password_hash: "32_LOWERCASE_HEX_SALT:128_LOWERCASE_HEX_SCRYPT_HASH"
# Optional if Cronometer two-factor authentication is enabled:
# vault_cronometer_totp_secret: "YOUR_TOTP_SECRET"
```

Enter actual values only in the local Vault editor. Do not commit plaintext
copies. The bridge login password is the separate password you enter during
ChatGPT OAuth sign-in; keep it in your password manager too.

The gateway hash must use upstream's scrypt format: a 16-byte salt encoded as
32 lowercase hex characters, a colon, then a 64-byte digest as 128 lowercase
hex characters. The hex salt is used as UTF-8 text when deriving the digest
with N=16384, r=8, p=1. A plaintext password is not a valid hash.

When enabled, missing or invalid required secrets stop deployment with the names of
the missing variables and a `make vault-edit` instruction. No secrets are
printed. Ansible writes a UID-10001-owned mode-0600 credential file at
`/etc/homelab/cronometer/credentials.env`, mounted at `/backend/.env` for the
upstream backend. It writes only a scrypt hash of the gateway password under
`/var/lib/homelab/cronometer/oauth/password-hash`. Secret-bearing tasks suppress
logs and diffs. Ansible copies the manually supplied Vault hash; it does not
generate passwords or perform password hashing.
OAuth and session state stay under `/var/lib/homelab/cronometer`; SELinux bind
mounts use `:Z`. Cronometer credential changes recreate the container; the
gateway reads its password hash on each login.

After the container is healthy, `make apply` manages a persistent Funnel route
from HTTPS port 443 to host localhost:8431. A short task file checks for
conflicts, then enables the route only if missing. Other ports are left alone;
other services on port 443 and active foreground routes require manual review.
No reset command is used.

The enable command has a 15-second limit. If Tailscale requires first-time
HTTPS/Funnel authorization, complete it and rerun `make apply`. Check mode skips
Funnel changes. Private unauthenticated MCP requests have been verified to
return 401; public reachability, OAuth metadata, and Android use still need
end-to-end testing. ChatGPT connects to `https://PUBLIC_HOST/mcp` with OAuth.

Runtime acceptance tests remain; the container has not been built or deployed. Diary writes require explicit disposable-entry
permission. Never repeat an uncertain write without checking the diary first.
Recipe yield/grams and Android ingredient editing remain unverified; upstream
weight recipes store ingredients in notes rather than an editable ingredient
list. Scanning is not implemented by this bridge.
