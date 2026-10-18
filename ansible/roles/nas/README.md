# NAS storage

This role verifies the configured disk's serial and exact byte size, then uses
[linux-system-roles.storage](https://github.com/linux-system-roles/storage)
(version 1.22.1) to manage whole-disk XFS and its persistent UUID mount at
`/srv/nas`. No partition table, LVM, or RAID is needed for this single-disk setup.
The upstream role installs its storage tooling and has Rocky Linux 10 variables.

## Install dependencies

Run `make setup`. External roles are installed under `ansible/roles/external/`
and excluded from Git. The controller uses the project virtual environment;
Ansible's managed-host Python must have access to system packages such as blivet.

## Initialize or reset

```sh
make nas-initialize
```

**This flag destroys existing storage on the identified disk, including an
existing XFS filesystem, on every invocation.** It is not just permission to
initialize a blank disk. Keep it out of inventory and use it only for deliberate
initialization or reset. Stop any services using the disk before resetting it.

Initialization asks the upstream role to remove the disk's existing storage,
then create and mount fresh XFS. It does not securely overwrite every data block.
If initialization is interrupted, rerunning with the flag starts fresh again.

## Normal runs

```sh
make apply
make check
```

Normal runs require existing whole-disk XFS and use the upstream role's safe
mode. Blank disks, old partitioned layouts, and other filesystem types are
rejected with initialization instructions. Existing files are preserved.

With both `--check` and `nas_initialize=true`, disk identity is checked and the
intended reset is reported, but storage tasks are skipped. Two successive role
calls cannot model deletion followed by creation without changing real state.

## Application storage

The role creates these root-owned directories with mode `0750` after mounting:

| Path under `/srv/nas` | Intended use |
| --- | --- |
| `shares/` | Samba shares; selected folders can later be exposed through FileBrowser Quantum |
| `backups/file-history/` | Windows File History backups |
| `backups/time-machine/` | macOS Time Machine backups |
| `immich/` | Immich-managed photo and video storage |

The filesystem mounts with `uquota,prjquota` to support future user and directory
quotas. No quota limits or project assignments are configured yet. See the
[RHEL XFS quota documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/managing_file_systems/limiting-storage-space-usage-on-xfs-with-quotas).
Quota accounting must be enabled on the initial mount; an already-mounted
filesystem without these options needs an unmount/mount or reboot to enable it.

Service deployment comes later, in this order:

1. Samba accounts, shares, permissions, and quotas.
2. File History and Time Machine shares and client backup verification.
3. Immich deployment, phone upload verification, and retention/cleanup settings.
4. FileBrowser Quantum and Caddy for external sharing after private access works.

These are storage placeholders, not configured services or usable network shares.
Each future service role should own the permissions of its child directories;
keep the top-level directories managed here root-owned. Do not recursively change
ownership of the entire NAS mount. Immich should manage its own storage; expose
only explicitly selected share directories through FileBrowser, rather than the
entire NAS mount. No Nextcloud deployment is planned.
