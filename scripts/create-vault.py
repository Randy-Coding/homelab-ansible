"""First-time Vault authoring; existing Vault files are never modified."""

import argparse
import getpass
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys
import tempfile

import yaml


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vault-file', type=Path, required=True)
    parser.add_argument('--key-file', type=Path, required=True)
    parser.add_argument('--inventory', type=Path, required=True)
    args = parser.parse_args()

    if args.vault_file.exists():
        return
    if not sys.stdin.isatty():
        parser.error('First-time Vault creation needs an interactive terminal.')

    inventory = yaml.safe_load(args.inventory.read_text())
    names = [user['name'] for user in inventory['samba_users']]
    if not names or len(set(names)) != len(names):
        parser.error('Configure a nonempty samba_users list with unique names first.')

    print('No Vault exists. Set Samba passwords now; deployment will continue afterward.')
    print('Use letters and digits only. Password input is hidden.')
    if input('Create the encrypted Vault? [y/N] ').lower() not in ('y', 'yes'):
        parser.exit(1, 'Cancelled; deployment was not started.\n')

    passwords = {}
    for name in names:
        while True:
            password = getpass.getpass(f'Samba password for {name}: ')
            confirmation = getpass.getpass(f'Confirm password for {name}: ')
            if not re.fullmatch(r'[A-Za-z0-9]+', password):
                print('Use a nonempty password containing only letters and digits.')
            elif password != confirmation:
                print('Passwords did not match. Try again.')
            else:
                passwords[name] = password
                break

    key = args.key_file.expanduser().resolve()
    repo = Path(__file__).resolve().parents[1]
    if key.is_relative_to(repo):
        parser.error('Keep the Vault unlock key outside the repository.')
    if not key.exists():
        key.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        fd = os.open(key, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w') as stream:
            stream.write(secrets.token_hex(32) + '\n')

    # Encrypt through stdin. Only encrypted bytes reach the temporary file.
    # Linking publishes it atomically and refuses to overwrite an existing Vault.
    args.vault_file.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=args.vault_file.parent) as temporary:
        encrypted = Path(temporary) / 'vault.yml'
        subprocess.run(
            [str(Path(sys.executable).parent / 'ansible-vault'), 'encrypt',
             '--vault-password-file', str(key), '--output', str(encrypted), '-'],
            input=yaml.safe_dump({'vault_samba_passwords': passwords}),
            text=True, capture_output=True, check=True,
        )
        os.link(encrypted, args.vault_file)

    print(f'Created encrypted Vault: {args.vault_file}')
    print(f'Back up the unlock key at {key} in your password manager.')
    print('Commit the encrypted Vault to Git; keep the unlock key outside Git.')


if __name__ == '__main__':
    try:
        main()
    except (EOFError, KeyboardInterrupt):
        sys.exit('Cancelled; deployment was not started.')
    except subprocess.CalledProcessError:
        sys.exit('Vault encryption failed. Check the local key and Ansible installation.')
