.PHONY: bootstrap setup lint deployment-ready check apply nas-initialize vault-edit

VAULT_FILE := ansible/inventory/host_vars/homelab/vault.yml
VAULT_PASSWORD_FILE ?= $(HOME)/.config/homelab/vault-password

bootstrap:
	@command -v uv >/dev/null 2>&1 || { \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	}

setup: bootstrap
	uv python install
	@test -x .venv/bin/python || uv venv --python 3.12
	uv pip install --python .venv/bin/python -r requirements.txt
	.venv/bin/ansible-galaxy role install -r ansible/requirements.yml -p ansible/roles/external
	.venv/bin/ansible-galaxy collection install -r ansible/requirements.yml

lint: setup
	.venv/bin/yamllint ansible

$(VAULT_FILE): | setup
	.venv/bin/python scripts/create-vault.py --vault-file "$@" --key-file "$(VAULT_PASSWORD_FILE)" --inventory ansible/inventory/host_vars/homelab/main.yml

vault-edit: setup
	.venv/bin/ansible-vault edit "$(VAULT_FILE)" --vault-password-file "$(VAULT_PASSWORD_FILE)"

# Add deployment commands here; shared requirements belong on deployment-ready.
check apply nas-initialize: deployment-ready

deployment-ready: lint $(VAULT_FILE)

check:
	.venv/bin/ansible-playbook ansible/playbooks/site.yml --check --diff --vault-password-file "$(VAULT_PASSWORD_FILE)"

apply:
	.venv/bin/ansible-playbook ansible/playbooks/site.yml --vault-password-file "$(VAULT_PASSWORD_FILE)"

# Destructive: erase the configured NAS disk and create fresh storage.
nas-initialize:
	.venv/bin/ansible-playbook ansible/playbooks/site.yml -e nas_initialize=true --vault-password-file "$(VAULT_PASSWORD_FILE)"
