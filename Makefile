.PHONY: check apply

check:
	ansible-playbook ansible/playbooks/site.yml --check --diff

apply:
	ansible-playbook ansible/playbooks/site.yml