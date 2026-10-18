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

This scaffold does not create Linux/Samba accounts or share directories, assign
permissions, label paths for SELinux, open the firewall, or configure quotas,
Time Machine, or File History. Those belong in the next implementation step;
adding a template entry alone does not make a share usable.

References: [smb.conf](https://www.samba.org/samba/docs/current/man-html/smb.conf.5)
and [testparm](https://www.samba.org/samba/docs/current/man-html/testparm.1.html).
