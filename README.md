# Homelab

## Vault secrets

The encrypted inventory file is tracked in Git. Its unlock password is stored
outside the repository at `~/.config/homelab/vault-password` and backed up in your
password manager. Use directory permissions `0700` and file permissions `0600`.
Anyone who can read the key can decrypt the Vault; without it, Git alone cannot
recover the secrets.

On the first `make apply` (or `make check`), if the encrypted file is missing:

1. Confirm that you want to create it.
2. Enter and confirm the Samba password for each configured user. Input is hidden;
   use a nonempty password containing only letters and digits.
3. A local unlock key is generated if missing, and standard Ansible Vault encrypts
   the secret variables. No editor or YAML authoring is needed.
4. Back up the local unlock key in your password manager, and commit the encrypted
   `vault.yml`. Its first line should begin with `$ANSIBLE_VAULT;`.

The first-time helper only creates a missing Vault. It does not decrypt, merge,
or rewrite existing Vault files, and no plaintext secret file is created. When
the Vault exists, Make skips onboarding entirely. Cancellation stops deployment.

Use `make vault-edit` to edit an existing Vault. When adding an account, add its
password there and reference it from `samba_users` in host inventory. Existing
Samba passwords are not automatically rotated by changing their Vault values.

## Unattended deployment

```sh
make check
make apply
```

After first-time creation, these commands read the local key automatically
without Vault prompts. Tailscale prompts for browser sign-in if needed during
`make apply`. If an existing Vault's key is missing or incorrect, restore the
original key; deployments fail rather than replacing it. Required Samba secrets
are checked before host-changing roles run. Existing Vault files are never
rewritten by deployments.

The key path can be overridden consistently for all Make commands:

```sh
make apply VAULT_PASSWORD_FILE=/path/outside/the/repository/vault-password
```

Samba uses the pinned `vladgh.samba` collection for its configuration and credential
management. Its local wrapper handles Linux users and firewall rules. Samba is
enabled after storage preparation in the main playbook. The family share, private user folders, and per-user Time Machine destinations
are configured with permissions and persistent SELinux mappings.

`make nas-initialize` also reads the key automatically. It is destructive: every
invocation erases and recreates the NAS filesystem.

## Docker

The local `docker` role delegates installation and service management to
`geerlingguy.docker`, pinned to version `8.0.0` in `ansible/requirements.yml`.
It uses Docker's official RHEL repository for this Rocky Linux host, installs
Engine, CLI, containerd, Buildx, and the Compose plugin, and enables Docker at
boot. Run `make setup` to install the role dependency, then `make check` to
preview and `make apply` to install and configure Docker.

The wrapper manages the repository with package signature checks enabled. DNF
handles the signing key during installation, avoiding an Ansible `rpm_key`
compatibility issue with OpenPGP v6 keys already installed on Rocky Linux 10.

Docker uses its default storage location, `/var/lib/docker`, and the local Unix
socket. Use `sudo docker` for interactive access; no users are added to the
Docker group. The default `local` logging driver rotates logs at 20 MB with five
files per container. Settings live in
`ansible/roles/docker/defaults/main.yml` and can be overridden in inventory.
Changing daemon settings can restart Docker; logging defaults apply to newly
created containers.

Normal applies install missing packages without requesting upgrades. For an
explicit upgrade of Engine and its plugins, run:

```sh
.venv/bin/ansible-playbook ansible/playbooks/site.yml \
  --vault-password-file "$HOME/.config/homelab/vault-password" \
  -e docker_upgrade=true
```

This runs the full playbook and may restart Docker. The upgrade flag controls
Ansible's package tasks; it does not prevent upgrades through other system tools.
Application deployment and push-triggered automation are outside this role.

## Tailscale

The pinned `artis3n.tailscale.machine` role installs Tailscale if missing and
enables and starts `tailscaled`. `state: present` leaves an installed version
unchanged. A local wrapper handles browser enrollment without requiring an OAuth
client or enrollment secret in Vault.

An already-connected NAS keeps its identity and skips the login prompt. When
sign-in is needed, `make apply` starts Tailscale, displays the browser sign-in
link, and pauses. Complete sign-in and press Enter; Ansible verifies the
connection before continuing. `make check` skips enrollment and prompts.
For persistent
server access, disable that device's key expiry in the Tailscale admin console.
Ansible does not manage this tailnet setting.

LAN Samba access remains enabled. Tailscale is an additional access path: use
the NAS's Tailscale IP or MagicDNS name instead of its LAN IP. Tailnet access
policies still determine which devices can connect; no tailnet policies or
additional firewall rules are changed by this configuration.

See [Samba access over Tailscale](ansible/roles/samba/README.md#access-over-tailscale)
for client connection addresses and credentials.
