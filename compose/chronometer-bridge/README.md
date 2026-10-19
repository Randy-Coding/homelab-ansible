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
`e123a4721093efa55adac665e10a546c105eb117`. Its only source adjustment makes the
gateway listen on the container interface so Docker's loopback port mapping can
reach it. Authentication stays enabled. Base images and Python dependencies
still need reproducible locks during the build stage.

Ansible deployment is in `ansible/roles/applications/tasks/cronometer.yml`.
It checks secret-file metadata without reading secrets, prepares directories,
copies the project, and runs Compose. Changed project files trigger a rebuild.
Check mode previews file changes and skips Compose; it cannot validate a build.
The role does not configure Funnel or create credentials.

The bridge is disabled by default. Once local credential setup is complete,
set these values in host inventory so normal `make apply` deploys it:

```yaml
cronometer_enabled: true
cronometer_public_url: https://YOUR_PUBLIC_HOST
```

Required local configuration:

- `CRONOMETER_PUBLIC_URL`: actual public HTTPS origin, without `/mcp`.
- `/etc/homelab/cronometer/credentials.env`: credentials entered locally, never
  in Git, commands, or chat. Mounted at `/backend/.env`, loaded by the upstream
  backend's existing dotenv support. Credentials are not passed to the gateway
  environment. Secure setup helper is not implemented yet. File owner must be
  UID 10001 with mode 0600, matching the container user.
- `/var/lib/homelab/cronometer`: persistent OAuth state, separate gateway login
  password hash, and Cronometer session cache. Owner UID/GID 10001, private
  permissions. Bind mounts use `:Z` for enforcing SELinux.
  The `oauth/password-hash` file must also have owner UID 10001 and mode 0600.

Funnel will forward HTTPS to host localhost:8431 after private OAuth tests.
Existing Serve/Funnel routes must be inspected and preserved. ChatGPT uses
`https://PUBLIC_HOST/mcp` with OAuth; Android tool use must be tested explicitly.

Do not deploy yet: local credential setup and runtime
acceptance tests remain. Diary writes require explicit disposable-entry
permission. Never repeat an uncertain write without checking the diary first.
Recipe yield/grams and Android ingredient editing remain unverified; upstream
weight recipes store ingredients in notes rather than an editable ingredient
list. Scanning is not implemented by this bridge.
