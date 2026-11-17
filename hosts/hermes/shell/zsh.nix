{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    histSize = 1000000000;
    histFile = "/home/amaddox/.zsh_history";

    shellAliases = {
      # Deploys this host; `make -C ~/nix-config switch HOST=<host>` deploys another.
      switch = "make -C ~/nix-config switch";
      update = "make -C ~/nix-config update";
    };

    interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/
      export ZSH_CUSTOM=${pkgs.oh-my-zsh}/share/oh-my-zsh/custom
      source $ZSH/oh-my-zsh.sh
    '';

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "man"
        "aws"
        "docker"
      ];
    };
  };
}
