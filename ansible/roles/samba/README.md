# Samba

Basic native Samba role for Rocky Linux. It installs Samba, templates
`/etc/samba/smb.conf`, validates it with `testparm`, and enables the `smb` service.
Configuration changes notify a restart handler. The role owns the complete
configuration file.

The role is not yet included in `ansible/playbooks/site.yml`. When accounts,
filesystem permissions, SELinux labels, and firewall access are ready, add
`samba` after `nas` in the playbook roles.

## Share configuration

Example inventory variables for a future share:

```yaml
samba_shares:
  - name: files
    path: /srv/nas/shares/files
    valid_users: ['@nas']
    read_only: false
```

`valid_users` is a required, nonempty list of Samba users or `@group` names.
Shares default to read-only and browseable; guest access is disabled. No shares
are defined by default. Existing Samba defaults handle protocol negotiation.

## Accounts and passwords

Set `samba_accounts` to the Linux usernames that should have Samba access and
`samba_group` to their shared group. The role creates missing Linux accounts
without home directories or login shells, and preserves existing accounts'
shells and supplementary groups.

The role checks Samba's account database using `pdbedit --list`. Missing entries
are created using `vault_samba_passwords` from the encrypted inventory file.
Passwords are supplied over standard input with `no_log`, and existing Samba
entries are not modified. There are no interactive deployment prompts.

Run `make vault-setup` once before deploying to create the local Vault key and
generate encrypted passwords. Rerun it after adding an account to generate only
that account's missing secret. Existing passwords and other Vault fields remain
unchanged. See the repository README for key storage and recovery.

Changing a Vault password value alone does not change an existing Samba account's
password; account password rotation is a separate explicit operation.

The role also opens the Samba service in `samba_firewall_zone`. Share-directory
permissions, SELinux labels, quotas, Time Machine, and File History still need
implementation; adding a template entry alone does not make a share usable.

References: [smb.conf](https://www.samba.org/samba/docs/current/man-html/smb.conf.5)
and [testparm](https://www.samba.org/samba/docs/current/man-html/testparm.1.html).
