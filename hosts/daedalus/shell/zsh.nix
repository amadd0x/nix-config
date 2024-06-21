{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    histSize = 1000000000;
    histFile = "/home/amaddox/zsh/history";

    shellAliases = {
      ll = "ls -alF";
      less = "less -i";
      dt = "date '+%Y-%m-%d %A %T %Z'";
      f = "find . | grep ";
      p = "ps aux | grep ";
      h = "history | grep -i ";
      rmd = "rm  --recursive --force --verbose ";
      ports = "sudo netstat -tulanp ";
    };

    interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/
      export ZSH_CUSTOM=${pkgs.oh-my-zsh}/share/oh-my-zsh/custom
      source $ZSH/oh-my-zsh.sh
      export NOMAD_ADDR=http://192.168.0.112:4646

      # Functions
      cheat() { curl cheat.sh/$1 ;}

      ## Unzip all the things
      extract () {
        if [ -f $1 ] ; then
            case $1 in
                *.tar.bz2)   tar xvjf $1    ;;
                *.tar.gz)    tar xvzf $1    ;;
                *.bz2)       bunzip2 $1     ;;
                *.rar)       unrar x $1     ;;
                *.gz)        gunzip $1      ;;
                *.tar)       tar xvf $1     ;;
                *.tbz2)      tar xvjf $1    ;;
                *.tgz)       tar xvzf $1    ;;
                *.zip)       unzip $1       ;;
                *.Z)         uncompress $1  ;;
                *.7z)        7z x $1        ;;
                *)           echo "don't know how to extract '$1'..." ;;
            esac
        else
            echo "'$1' is not a valid file!"
        fi
      }

      ## Show all running processes matching a given name
      pss() {
          ps aux | grep "$1" | grep -v grep
      }

      ## Backup file or directory
      backup() {
          if [ -z "$1" ]; then
              echo "Usage: backup <file or directory>"
              return 1
          fi

          local timestamp=$(date +%Y%m%d%H%M%S)
          local basename=$(basename "$1")
          local backup_name="\$\{basename}_\$\{timestamp}.bak"

          cp -r "$1" "$backup_name"
          echo "Backup created: $backup_name"
      }

      ## Searches for text in all files in the current folder
      ftext() {
        grep -iIHrn --color=always "$1" . | less -r
      }

    '';

    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    ohMyZsh = {
      enable = true;
      plugins = ["git"];
    };
  };
}
