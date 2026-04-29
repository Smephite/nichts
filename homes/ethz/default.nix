{
  pkgs,
  lib,
  ...
}: let
  user = "msc25h18";
  realHome = "/home/${user}";
in {
  home.username = user;
  home.homeDirectory = "${realHome}/nix-home";
  home.stateVersion = "25.05";

  # --- Shell ---
  programs.bash = {
    enable = true;
    historyFile = "${realHome}/nix-home/.bash_history";
    sessionVariables = {
      EDITOR = "nano";
      PAGER = "less -R";
    };
    shellAliases = {
      ll = "eza -l --git";
      la = "eza -la --git";
      cat = "bat -p";
    };
    initExtra = ''
      # Visual marker so you always know you're inside nix-home
      export PS1='\[\e[1;35m\][nix-home]\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\] \$ '

      # Make sure HM session vars are loaded
      [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ] && \
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';
  };

  # --- Tools ---
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    terminal = "tmux-256color";
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.git = {
    enable = true;
    userName = "Kai";
    userEmail = "..."; # fill in
    extraConfig.init.defaultBranch = "main";
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq-go
    htop
    btop
    file
    tree
    git-lfs
    gnumake
    curl
    wget
  ];

  # XDG inside nix-home, isolated from host
  xdg.enable = true;
}
