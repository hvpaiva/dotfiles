# Bash completion sources

The files in this directory are upstream scripts for CLIs without a completion
generator. The loaders in `~/.local/share/bash-completion/completions/` source them
on the first Tab. They override distro files without modifying system packages.

| Script | Upstream version | Source |
| --- | --- | --- |
| `eza.bash` | 0.23.5 | [eza completion](https://github.com/eza-community/eza/blob/98442ab17c2c3738701b62a7e060b1431ae2d6ea/completions/bash/eza) |
| `hyperfine.bash` | 1.20.0 | `autocomplete/hyperfine.bash` from the [official release](https://github.com/sharkdp/hyperfine/releases/tag/v1.20.0) |

The adjacent license files come from the same upstream versions. Keep these
scripts and licenses together when updating them.

The other completion loaders call each CLI's generator on demand. They use the
version active on that host and do not install missing tools.
