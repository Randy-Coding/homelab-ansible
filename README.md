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
without prompts. If an existing Vault's key is missing or incorrect, restore the
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
