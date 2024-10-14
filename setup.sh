#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

if ! command -v ansible-playbook &>/dev/null; then
	echo "Command ansible-playbook could not be found!"
	echo
	echo "You can install ansible by below commands:"
	echo
	echo "  pipx install --include-deps ansible"
	exit 1
fi

ANSIBLE_PLAYBOOK_ARGS=()

function usage() {
	echo "Usage: setup.sh [OPTIONS]"
	echo
	echo "Options:"
	echo ""
	echo "--help   Show this message and exit"
	echo "--check  Run the playbook in check mode (default: false)"
	echo "--meli   Run specific playbooks for Meli environment (default: false)"
	exit 0
}

# idiomatic parameter and option handling in sh
while test $# -gt 0; do
	case "$1" in
	--check) ANSIBLE_PLAYBOOK_ARGS+=("--check") ;;
	--meli) MELI_FLAG=true ;;
	--help) usage ;;
	--*) echo "bad option $1" ;;
	*) usage ;;
	esac
	shift
done

# Check if the script is running in GitHub Actions by checking for the GITHUB_ACTIONS environment variable
if [ -z "$GITHUB_ACTIONS" ]; then
	# Local environment: check for password file or create it
	BECOME_PASS_FILE="$HOME/.become_pass"
	if [ ! -f "$BECOME_PASS_FILE" ]; then
		echo ".become_pass file not found in home directory. Creating a new one."
		echo "Enter the sudo password that will be used by Ansible:"
		read -s SUDO_PASS
		echo "$SUDO_PASS" >"$BECOME_PASS_FILE"
		chmod 600 "$BECOME_PASS_FILE"
	fi

	# Read the password from the .become_pass file
	BECOME_PASS=$(cat "$BECOME_PASS_FILE")
else
	# GitHub Actions environment: no password needed, so we set BECOME_PASS as an empty string
	BECOME_PASS=""
fi

cd ./ansible
ansible-galaxy collection install -r requirements.yml --upgrade
ansible-playbook setup.yml --extra-vars "ansible_become_password=${BECOME_PASS} meli=${MELI_FLAG}" ${ANSIBLE_PLAYBOOK_ARGS[@]}
