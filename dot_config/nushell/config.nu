# --- Core behaviour ----------------------------------------------------------
$env.config.show_banner   = false
$env.config.edit_mode     = 'vi'        # reedline supports 'vi' or 'emacs' :contentReference[oaicite:1]{index=1}
$env.config.buffer_editor = 'hx'

# --- Aliases ------------------------------------------------------------------
alias dl   = docker ps
alias dc   = docker-compose
alias dv   = docker volume ls
alias dce  = docker-compose exec
alias dcs  = docker-compose stop
alias dcd  = docker-compose down
alias dcb  = docker-compose build
alias dcu  = docker-compose up -d
alias dlog = docker-compose logs -f
alias dx   = docker system prune -a -f
alias dub  = docker-compose up -d --build
alias l    = eza -l --icons --git -a
alias lt   = eza --tree --level=2 --long --icons --git
alias ltree = eza --tree --level=2 --icons --git
alias vi   = /opt/homebrew/bin/nvim
alias v    = /opt/homebrew/bin/nvim
alias vim  = /opt/homebrew/bin/nvim
alias cl   = clear
alias ..   = cd ..
alias ...  = cd ../..
alias bk   = cd -
alias home = cd ~

# --- Functions ----------------------------------------------------------------
# mkdir + cd
def mkd [...dirs] {
  mkdir $dirs
  if $dirs != [] { cd ($dirs | last) }
}

# Get Fury tiger token and copy to clipboard
def fgt [] {
  let token = (fury get-token | lines | find Bearer)
  $env.TIGER_TOKEN = $token
  echo $env.TIGER_TOKEN | pbcopy
  print "TIGER_TOKEN set and copied to clipboard."
}

# Copy file contents to clipboard
def cp_file [file: path] {
  open -r $file | pbcopy
}

def now [] {
  date now | format date "%Y-%m-%d %H:%M:%S"
}

def zlj [session = "home"] {
  zellij -a $session
}


source ~/.config/nushell/zoxide.nu
source ~/.config/nushell/starship.nu
