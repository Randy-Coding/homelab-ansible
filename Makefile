.PHONY: bootstrap setup check apply

bootstrap:
	@command -v uv >/dev/null 2>&1 || { \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	}

setup: bootstrap
	uv python install
	@test -x .venv/bin/python || uv venv --python 3.12
	uv pip install --python .venv/bin/python -r requirements.txt
	.venv/bin/ansible-galaxy collection install -r ansible/requirements.yml

check: setup
	.venv/bin/ansible-playbook ansible/playbooks/site.yml --check --diff

apply: setup
	.venv/bin/ansible-playbook ansible/playbooks/site.yml