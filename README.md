# :construction: Under Construction :construction:

This repository contains my personal nix configs. I am learning.  If you want to re-use anything here your mileage may vary.  If you're learning as well, here are some resources I've found helpful:


### Starter Config
https://github.com/Misterio77/nix-starter-configs

### Mature Configs
https://github.com/hlissner/dotfiles#frequently-asked-questions (A gentle warning)
https://github.com/Misterio77/nix-config

### Videos

2h, Comprehensive "What is Nix": https://youtu.be/6Le0IbPRzOE
28m, Containerization with Nix: https://youtu.be/5XY3K8DH55M
15m, Everything Everywhere all at Once: https://youtu.be/CwfKlX3rA6E
9m, Nix Language Explained: https://youtu.be/UgrwoAGSPOQ
9m, Impermanence Setup: https://youtu.be/YPKwkWtK7l0
7m, NixOS Secrets Management: https://youtu.be/G5f6GC7SnhU

### Links

Structured Learning: https://nixos.org/guides/nix-pills/
Discuss: https://discourse.nixos.org/
Awesome-List: https://github.com/nix-community/awesome-nix
Wiki: https://nixos.wiki/wiki
ISO from Nix: https://nix.dev/tutorials/nixos/building-bootable-iso-image
Zero to Nix: https://zero-to-nix.com/start
NixOS with Flakes: https://nixos-and-flakes.thiscute.world/introduction/
How to Upgrade Packages: https://discourse.nixos.org/t/how-to-upgrade-packages/6151/9

Configure Docker: https://nixos.wiki/wiki/Docker
Configure Zsh: https://nixos.wiki/wiki/Zsh
Configure OpenVPN: https://nixos.wiki/wiki/OpenVPN

### Tips

Use `nix repl` to test expressions and browse your flake.

`nix repl`, then `:lf . ` to load your flake.nix.  You can <tab> to complete paths and explore your flake's structure and `nixosConfigurations.<host>`.  For example, `nixosConfigurations.<host>.pkgs.<package-name>.` will show you the available options and current configuration for a given package.

`:q` to exit.
