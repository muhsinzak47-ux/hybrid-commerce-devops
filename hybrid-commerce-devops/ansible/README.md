# Ansible Playbook Guide

## Prerequisites
1. Install Ansible: `pip install ansible`
2. Set up SSH keys for target server
3. Update `ansible/inventory/hosts.yml` with server details

## Usage
```bash
# Run full playbook
cd ansible
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --ask-become-pass

# Dry run
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check

# With extra variables
ansible-playbook playbooks/site.yml -i inventory/hosts.yml \
  -e "app_port=9000 environment=staging"
```

## Security
- Use Ansible Vault for secrets: `ansible-vault encrypt group_vars/all.yml`
- Never commit `.env` files or SSH keys
- Review SSH hardening role before production use
