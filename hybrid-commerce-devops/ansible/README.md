# Run full playbook
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --ask-become-pass

# Run only common setup
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --ask-become-pass --tags common

# Run only Docker setup
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --ask-become-pass --tags docker

# Dry run
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check
