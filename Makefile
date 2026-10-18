.PHONY: bootstrap setup check apply nas-initialize

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

check: setup
	.venv/bin/ansible-playbook ansible/playbooks/site.yml --check --diff

apply: lint
	.venv/bin/ansible-playbook ansible/playbooks/site.yml

# Destructive: erase the configured NAS disk and create fresh storage.
nas-initialize: lint
	.venv/bin/ansible-playbook ansible/playbooks/site.yml -e nas_initialize=true
