# --- Core environment --------------------------------------------------------
$env.EDITOR = "hx"
$env.GPG_TTY = (tty)
$env.DOTNET_CLI_TELEMETRY_OPTOUT = "1"
$env.HOMEBREW_NO_ANALYTICS     = "1"
$env.GOPATH = $"($env.HOME)/go"
$env.GOBIN  = $"($env.GOPATH)/bin"
$env.STARSHIP_CONFIG = $"($env.HOME)/.config/starship/starship.toml"
$env.OP_BIOMETRIC_UNLOCK_ENABLED = "true"
$env.MELI_ENV = "true"
$env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
$env.PAGER = "bat --paging always"

# Java home (requires asdf installed)
$env.JAVA_HOME = (asdf where java | str trim)

# --- Conditional block for Mercado Livre environment -------------------------
if $env.MELI_ENV == "true" {
  $env.GOPRIVATE   = "github.com/mercadolibre/*,github.com/melisource/*"
  $env.GONOSUMDB   = $env.GOPRIVATE
  $env.GONOPROXY   = $env.GOPRIVATE
  $env.GOPROXY     = "https://proxy.golang.org,direct,https://go.artifacts.furycloud.io"
}

# --- PATH construction -------------------------------------------------------
let extra_paths = [
  "/opt/homebrew/bin"
  "/opt/homebrew/bin/brew"
  "/opt/homebrew/sbin"
  $"($env.HOME)/.cargo/bin"
  $"($env.HOME)/.local/share/nvim/mason/bin"
  $"($env.HOME)/.srvc_cli/venv/bin"
  $"($env.HOME)/.fury/fury_venv/bin"
  $"($env.HOME)/.local/bin"
  $"($env.HOME)/.scripts/bin"
  $"($env.GOBIN)"
  $"($env.HOME)/.codeium/windsurf/bin"
]
$env.PATH = ($env.PATH | split row (char esep) | append $extra_paths | uniq)

# --- zoide init --------------------------------------------------------------
$env._ZO_DATA_DIR = $"($env.HOME)/.local/share/zoxide"
$env._ZO_RESOLVE_SYMLINKS = 1
$env._ZO_ECHO = 1


# --- starship init --------------------------------------------------------------
$env.STARSHIP_SHELL = "nu"

zoxide init nushell | save -f ~/.config/nushell/zoxide.nu
starship init nu | save -f ~/.config/nushell/starship.nu
