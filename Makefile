.PHONY: bootstrap setup lint check apply nas-initialize vault-setup vault-edit

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

vault-setup: setup
	.venv/bin/ansible-playbook -i localhost, ansible/playbooks/vault-setup.yml -e 'vault_password_file=$(VAULT_PASSWORD_FILE)'

vault-edit: setup
	.venv/bin/ansible-vault edit "$(VAULT_FILE)" --vault-password-file "$(VAULT_PASSWORD_FILE)"

check: lint
	.venv/bin/ansible-playbook ansible/playbooks/site.yml --check --diff --vault-password-file "$(VAULT_PASSWORD_FILE)"

apply: lint
	.venv/bin/ansible-playbook ansible/playbooks/site.yml --vault-password-file "$(VAULT_PASSWORD_FILE)"

# Destructive: erase the configured NAS disk and create fresh storage.
nas-initialize: lint
	.venv/bin/ansible-playbook ansible/playbooks/site.yml -e nas_initialize=true --vault-password-file "$(VAULT_PASSWORD_FILE)"
