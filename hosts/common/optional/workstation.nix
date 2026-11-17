# Desktop machines I sit at (atlas, hermes): shell, audio, printing, and the
# apps I want everywhere. The desktop environment itself stays per host.
{pkgs, ...}: {
  imports = [./zsh.nix];

  users.defaultUserShell = pkgs.zsh;

  environment.variables.EDITOR = "code --wait";

  # X11 / keyboard
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Sound with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    zsh
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
    ghostty

    # Desktop utilities
    xclip
    glib-networking
    flameshot
    peek
    termdown
    remmina
    vlc
    inkscape
    qFlipper

    # System / CLI
    busybox
    mailutils
    memtester
    unrar-wrapper

    # Apps
    google-chrome
    slack
    teams-for-linux
    discord
    steam
    prismlauncher
    lmstudio
    pkgs.unstable.code-server
  ];
}
