# Homelab

## Unattended Vault use

Run once before deployment:

```sh
make vault-setup
```

An Ansible playbook creates a random Vault key at
`~/.config/homelab/vault-password`, with directory mode `0700` and file mode
`0600`. It generates random alphanumeric Samba passwords for the accounts in
inventory and writes them directly to an encrypted
`ansible/inventory/host_vars/homelab/vault.yml`. Plaintext secrets are not written
to a temporary file or printed in task output.

Commit the encrypted `vault.yml` to Git. The unlock key is outside the repository;
back it up in your password manager. Losing it means the encrypted secrets cannot
be recovered from Git. Anyone with access to the key can decrypt the Vault.

Normal deployments do not generate or rotate secrets:

```sh
make check
make apply
```

Both read the key automatically, without prompts. If the key is missing, restore
it first. Do not generate a new key for an existing encrypted Vault. The setup
playbook refuses to do that and fails if an existing key cannot decrypt the file.

Use `make vault-edit` to view or edit passwords in your editor. After adding an
account in inventory, rerun `make vault-setup`: it preserves existing secrets and
adds only missing account passwords. This does not rotate existing Samba account
passwords. Samba service configuration is still being developed and is not yet
enabled in the main playbook.

To use another key location, pass the same override to every Make command:

```sh
make apply VAULT_PASSWORD_FILE=/path/outside/the/repository/vault-password
```

`make nas-initialize` also uses the key automatically. It remains a destructive
operation that erases and recreates the NAS filesystem on every invocation.
