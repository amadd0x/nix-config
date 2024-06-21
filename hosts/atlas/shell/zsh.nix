{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    histSize = 1000000000;
    histFile = "/home/amaddox/zsh/history";

    shellAliases = {
      switch = "cd ~/nix-config; make switch_atlas; cd -;";
      update = "cd ~/nix-config; make update; cd -;";
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
