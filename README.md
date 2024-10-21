# Dotfiles

```sh
██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```

[![test](https://github.com/hvpaiva/dotfiles/actions/workflows/tests.yml/badge.svg)](https://github.com/hvpaiva/dotfiles/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![dotfiles](imgs/dotfiles.png)
![dashboard](imgs/nvim-dash.png)

All the configuration and scripts needed for my working environment. Proper dotfiles are at the core of an efficient setup—no more, no less.

All configurations are managed using [Ansible](https://github.com/ansible/ansible). While it’s a bit more complex than tools like [GNU Stow](https://www.gnu.org/software/stow/) or [dotbot](https://github.com/anishathalye/dotbot), Ansible provides much richer features to bootstrap my environment.

> **Important:**  
> This project is not intended to be a fully-fledged Linux distribution or for direct duplication. It is highly personalized for my own use and may only serve as inspiration for others. If you find anything odd or incorrect, feel free to open an issue.

## Note

Even though the configuration is set up to work on Linux, I have never actually used it in practice. The setup was created but hasn't been tested or deployed in a real-world working environment yet.

## Setup

Cloning Dotfiles:

```sh
git clone git@github.com:hvpaiva/dotfiles.git
```

Navigate to the project directory and run the `setup.sh` playbook:

```sh
cd dotfiles && ./setup.sh
```

> **Note:**  
> You will be prompted for your `sudo` password the first time you run the configuration. After this, it will be securely stored.  
> If you're using a shared or unsecured machine, make sure to remove sensitive information.

## Manifest

- **Terminals**:
  - [kitty](https://sw.kovidgoyal.net/kitty/)
  - [tmux](https://github.com/tmux/tmux)
- **Shell**:
  - [zsh](https://www.zsh.org/)
  - [zinit](https://github.com/zdharma-continuum/zinit)
  - [starship](https://github.com/starship/starship)
- **Editor**:
  - [neovim](https://github.com/neovim/neovim)
- **Theme**:
  - [TokyoNight](https://github.com/folke/tokyonight.nvim)
- **Font**:
  - Fira Code (Nerd Fonts version)
- **Browser**:
  - [nnn](https://github.com/jarun/nnn)
- **Version Manager**:
  - [asdf](https://github.com/asdf-vm/asdf)
- **Others**:
  - lazygit
  - gitui
  - bat
  - ideavim
- ...

## Contributing

Issues and Pull Requests are greatly appreciated. If you’re new to contributing to open-source projects, I’d be happy to help you get started.

You can begin by [opening an issue](https://github.com/hvpaiva/dotfiles/issues/new) describing the problem you're trying to solve, and we'll take it from there.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/mit-license.php) © Highlander Paiva.

## Acknowledgement

This repository is inspired by the [dotfiles](https://github.com/jeffreytse/dotfiles) created by [jeffreytse](https://github.com/jeffreytse).
