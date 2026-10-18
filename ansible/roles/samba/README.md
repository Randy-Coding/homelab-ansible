# Samba

This local role handles Linux accounts and firewalld, then delegates Samba
packages, configuration, share directories, credentials, and service management
to the pinned `vladgh.samba.server` role. No custom password prompts or
credential-database logic are maintained here.

## Accounts

Host inventory defines accounts and references secrets from the encrypted Vault:

```yaml
samba_group: nas
samba_users:
  - name: randy
    password: "{{ vault_samba_passwords.randy }}"
```

A corresponding Linux account is created if missing, with no home or login shell.
Existing accounts retain their shell and other group memberships.

Passwords must be nonempty alphanumeric strings. This policy avoids shell
quoting and `echo` interpretation problems in the pinned upstream credential
task. Secret-bearing validation and upstream credential tasks use `no_log`.
Existing Samba passwords are not rotated when Vault values change; password
rotation remains an explicit operation.

## Shares

Shares use the upstream collection's format. In particular, `valid_users` is a
Samba string, not the list used by the old custom template:

```yaml
samba_shares:
  - name: family
    path: /srv/nas/shares/family
    valid_users: '@nas'
    group: nas
    owner: root
    read_only: false
    create_mode: '0660'
    force_create_mode: '0660'
    directory_mode: '2770'
    force_directory_mode: '2770'
    setype: samba_share_t
```

Host inventory currently enables the `family` share. Samba's `[homes]` feature
and `homes.conf.j2` provide each configured account's private share; the local
role creates its owner-only directory. Persistent SELinux mappings cover the
shares tree, and the NAS role labels the mount directory itself.

## Access over Tailscale

Samba listens on all interfaces by default, including `tailscale0`. The playbook
connects Tailscale before configuring Samba. The same shares, Samba usernames,
passwords, and file permissions apply over LAN and Tailscale.

After `make apply`, run `tailscale ip -4` on the NAS to find its Tailscale IP.
Install and sign in to Tailscale on the client, then connect using that IP:

- macOS Finder → Go → Connect to Server: `smb://100.x.y.z/family`
- Windows File Explorer: `\\100.x.y.z\family`
- Time Machine destination: `smb://100.x.y.z/time-machine-randy`

Replace `100.x.y.z` with the NAS's actual Tailscale IP. Its MagicDNS name also
works when enabled in your tailnet. Sign in with the Samba account configured in
inventory. Tailnet access policies must allow the client to reach TCP port 445
on the NAS. Use a direct address; share discovery does not cross Tailscale.

Tailscale's default netfilter mode accepts incoming tailnet traffic. If you
customize its netfilter mode or the host firewall, ensure SMB traffic on
`tailscale0` is allowed too.

## Time Machine

Each configured Samba account also gets a dedicated `time-machine-USERNAME`
share under `samba_shares_root`. The collection creates the directory with that
user as owner and mode `0700`; file masks are `0600`. Only that user may connect.
These generated shares are appended to the explicit inventory shares; add new
accounts to `samba_users` rather than writing extra Time Machine share entries.

Apple extensions and `fruit streams_xattr` are enabled globally to avoid
negotiation depending on which share a Mac connects to first. The backup shares
set `fruit:time machine = yes` through the collection's VFS options. Rocky's
`samba` package supplies both modules. No capacity limit is imposed.

After `make apply`, connect in Finder using:

```text
smb://192.168.1.245/time-machine-randy
```

Use that account's Samba credentials, then select the mounted destination in
macOS Time Machine settings and enable backups. Backup scheduling remains on the
Mac. Automatic network discovery is not configured here; connect directly by IP
or an already-configured Tailscale name. Test a backup and file restore from the
Mac before relying on the destination.

The role runs after `nas` in `site.yml`. NetBIOS/WINS browser-master features
remain disabled. Windows File History is configured on each Windows client;
it does not require Time Machine's VFS settings.

See the root README for Vault creation and unattended deployment. See the
[upstream documentation](https://github.com/vladgh/ansible-collection-vladgh-samba)
for supported share options.
