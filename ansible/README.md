


# Ansible Setup for macOS

## Requirements

The installation script handles all the necessary dependencies to run Ansible on macOS, such as **Homebrew**, **pipx**, and **Ansible**.

### What the script does:

1. Checks if Homebrew is installed. If not, it will be installed automatically.
2. Checks if `pipx` is installed. If not, it will be installed via Homebrew.
3. Installs Ansible via Homebrew (or `pipx` as a fallback if necessary).
4. Runs the Ansible playbook (`mac.yml`) configured for your project.

## How to run the script

1. Make the `install` file executable:

```bash
chmod +x install
```

2. Run the installation script:

```bash
./install
```

During the process, you may be prompted to provide your administrator (sudo) password, depending on the tasks configured in the playbook.
