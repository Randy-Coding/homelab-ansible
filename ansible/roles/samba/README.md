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

This is an example, not an enabled share. Private directories need their own
owner, access restrictions, and restrictive masks; do not reuse family-share
permissions for them. Persistent SELinux path mappings are still needed.

The role is included after `nas` in `site.yml`. No shares are enabled yet;
share permissions and persistent SELinux mappings are the next configuration
step. Modern SMB is configured without NetBIOS/WINS browser-master features.
Time Machine and discovery will be configured later. Host inventory holds these
settings so they take precedence over the collection's own defaults.

See the root README for Vault creation and unattended deployment. See the
[upstream documentation](https://github.com/vladgh/ansible-collection-vladgh-samba)
for supported share options.
