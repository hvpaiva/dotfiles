# home.nix
# home-manager switch 

{ config, pkgs, ... }:

{
  home.username = "hpaiva";
  home.homeDirectory = "/Users/hpaiva";
  home.stateVersion = "24.11"; # Please read the comment before changing.

# Makes sense for user specific applications that shouldn't be available system-wide
  home.packages = [
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
   home.file = {
    ".zshrc".source = "${config.home.homeDirectory}/dotfiles/zshrc/.zshrc";
    ".config/wezterm".source = "${config.home.homeDirectory}/dotfiles/wezterm";
    ".config/skhd".source = "${config.home.homeDirectory}/dotfiles/skhd";
    ".config/starship".source = "${config.home.homeDirectory}/dotfiles/starship";
    ".config/zellij".source = "${config.home.homeDirectory}/dotfiles/zellij";
    ".config/nvim".source = "${config.home.homeDirectory}/dotfiles/nvim";
    ".config/nix".source = "${config.home.homeDirectory}/dotfiles/nix";
    ".config/nix-darwin".source = "${config.home.homeDirectory}/dotfiles/nix-darwin";
    ".config/tmux".source = "${config.home.homeDirectory}/dotfiles/tmux";
    ".config/ghostty".source = "${config.home.homeDirectory}/dotfiles/ghostty";
   };


  home.sessionVariables = {
  };

  home.sessionPath = [
    "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
  ];
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    initExtra = ''
      # Add any additional configurations here
      export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';
  };
}
