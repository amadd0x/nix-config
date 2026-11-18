# Git identity and GitHub SSH config shared by every machine amaddox uses.
# Imported by home.nix (atlas, standalone home-manager) and by hosts that run
# home-manager as a NixOS module (hermes).
#
# The private key is NOT managed here: each machine has its own ~/.ssh/github,
# generated locally and added to the amadd0x GitHub account, so a lost machine's
# key can be revoked on its own.
{...}: {
  programs.ssh = {
    enable = true;
    # Don't emit home-manager's legacy defaults; the "*" block below is explicit.
    enableDefaultConfig = false;
    # Tools that write ssh config themselves (DevPod, Coder) can't edit the
    # read-only ~/.ssh/config home-manager creates; point them at this file instead.
    includes = ["~/.ssh/config.local"];
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/github";
        IdentitiesOnly = true;
      };
      "*" = {
        AddKeysToAgent = "yes";
      };
    };
  };

  programs.git = {
    enable = true;
    # Git LFS: installs git-lfs and adds its filter to ~/.config/git/config
    lfs.enable = true;
    settings = {
      user = {
        name = "amadd0x";
        email = "amadd0x@github.com";
      };
      alias = {
        current-branch = "!git branch | grep '*' | cut -d ' ' -f2";
        flatten = "!git reset $(git merge-base master $(git current-branch)) && git add -A";
        flatten-main = "!git reset $(git merge-base main $(git current-branch)) && git add -A";
      };
    };
  };
}
