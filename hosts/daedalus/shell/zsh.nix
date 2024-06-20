{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    histSize = 1000000000;
    histFile = "/home/amaddox/zsh/history";

    shellAliases = {
      switch = "cd ~/nix-config; sudo nixos-rebuild switch --flake .#daedalus; cd -;";
      update = "cd ~/nix-config; sudo nix flake update; cd -;";
      update-switch = "cd ~/nix-config; sudo nix flake update; sudo nixos-rebuild switch --flake .#daedalus; cd -;";
    };

    interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/
      export ZSH_CUSTOM=${pkgs.oh-my-zsh}/share/oh-my-zsh/custom
      source $ZSH/oh-my-zsh.sh
      export NOMAD_ADDR=http://192.168.0.112:4646
    '';

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    ohMyZsh = {
      enable = true;
      plugins = ["git"];
    };
  };
}
