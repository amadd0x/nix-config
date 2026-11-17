# How this repo is organized

This is a guide for anyone new to NixOS who wants to understand what's here and
adapt it for their own machines. It assumes you've installed NixOS once and
seen `/etc/nixos/configuration.nix`, but not much more.

## The big idea

A fresh NixOS install has one file, `/etc/nixos/configuration.nix`, describing
one machine. This repo does the same thing for **several machines from one git
repo**:

- Each machine's config is split into small files by topic (desktop, services,
  shell, ...), and the files are combined with `imports`.
- Settings shared by several machines live in one place (`hosts/common/`)
  instead of being copied.
- A **flake** (`flake.nix` + `flake.lock`) pins the exact version of every
  dependency, so a build today and a build in six months produce the same system.

Every file is a NixOS **module**: a function returning a set of options. NixOS
merges all imported modules into one config. Order doesn't matter, and lists
like `environment.systemPackages` are concatenated across files rather than
overwritten.

## Map

```
.
├── flake.nix                 # entrypoint: inputs (dependencies) + outputs (machines)
├── flake.lock                # exact pinned revision of every input (generated)
├── Makefile                  # shortcuts: switch, install, update, gc
├── .sops.yaml                # which keys can decrypt secrets (see secrets.md)
│
├── hosts/
│   ├── common/
│   │   ├── global/           # baseline every host should import
│   │   └── optional/         # opt-in pieces a host imports if it wants them
│   ├── atlas/                # desktop workstation
│   ├── daedalus/             # home server
│   └── hermes/               # laptop
│
├── home-manager/home.nix     # per-user config (dotfiles, user packages)
├── modules/                  # reusable modules you'd share with others (empty templates)
├── overlays/                 # changes to the package set: adds pkgs.unstable, custom pkgs
├── pkgs/                     # your own package definitions
└── docs/                     # you are here
```

## `flake.nix`: the entrypoint

**Inputs** are everything the config depends on, each a git repo:

| Input | What it provides |
|---|---|
| `nixpkgs` | The package set and NixOS modules, tracking a **stable release** (`nixos-25.11`) |
| `nixpkgs-unstable` | Newer package versions, used per package as `pkgs.unstable.<name>` |
| `home-manager` | Per-user configuration. Its release must match `nixpkgs`. |
| `sops-nix` | Decrypts secrets on the machine (see [secrets.md](secrets.md)) |
| `disko` | Declarative disk partitioning, used for fresh installs |

`flake.lock` records the exact commit of each input. `make update` refreshes it;
nothing changes version until you do that.

**Outputs** are what the flake builds. The important one is
`nixosConfigurations`, with one entry per machine:

```nix
hermes = lib.nixosSystem {
  specialArgs = {inherit inputs outputs;};   # lets modules use `inputs.*` / `outputs.*`
  modules = [./hosts/hermes];               # i.e. hosts/hermes/default.nix
};
```

The entry name is what you build: `nixos-rebuild switch --flake .#hermes`.

## `hosts/`: one directory per machine

A host's config is layered. The bottom layers are shared, the top is specific:

```
hosts/hermes/default.nix
 ├── ../common/global            every machine: Home Manager, OpenSSH, known_hosts, overlays
 ├── ../common/optional/dev.nix  only workstations: dev tooling, Docker, direnv
 ├── ../common/optional/tailscale.nix
 ├── ./configuration.nix         this machine: hostname, bootloader, desktop, users
 ├── ./hardware-configuration.nix  generated: kernel modules, CPU, (filesystems)
 ├── ./disko.nix                 this machine's disk layout
 └── ./shell/zsh.nix
```

Files in a host directory:

| File | Purpose | Hand-edited? |
|---|---|---|
| `default.nix` | Entrypoint: `imports` + host-specific packages | Yes |
| `configuration.nix` | The equivalent of `/etc/nixos/configuration.nix` | Yes |
| `hardware-configuration.nix` | Detected hardware. Regenerate with `nixos-generate-config` rather than editing. | Rarely |
| `disko.nix` | Partitions, encryption, filesystems (hermes only so far) | Yes |
| `services/` | One file per service (Syncthing, Tailscale, backups, ...) | Yes |
| `shell/` | Shell config | Yes |
| `secrets/secrets.yaml` | Encrypted secrets, edited with `sops` | Via `sops` only |
| `ssh_host_ed25519_key.pub` | The machine's SSH identity, pinned in every other host's known_hosts | No |

**`common/global/`** holds things every machine should have: Home Manager
wiring, the overlays, `allowUnfree`, hardened OpenSSH, and auto-upgrade (off
unless a host enables it). hermes and daedalus import it. atlas predates it and
still sets these up itself; moving it onto `common/global` is a pending cleanup.

**`common/optional/`** holds pieces that only some machines want. Import one by
path from a host's `default.nix`. Adding a new optional module is just adding a
file here.

> **Where should a setting go?** Ask whether you'd want it on a *new* machine
> by default. If yes, `common/global/`. If some machines want it, a new file in
> `common/optional/`. If only this one, the host directory.

## Packages: stable, unstable, and your own

- `pkgs.firefox`: from the stable `nixpkgs` input.
- `pkgs.unstable.claude-code`: from `nixpkgs-unstable`, for things that move
  faster than the stable release. This comes from the `unstable-packages`
  overlay in `overlays/default.nix`.
- `pkgs/`: your own package definitions. The `additions` overlay makes them
  available as `pkgs.<name>`.
- `overlays/default.nix` → `modifications`: patch or override existing packages.

System-wide packages go in `environment.systemPackages` (every user gets them).
Search for names at [search.nixos.org](https://search.nixos.org/packages).

## Home Manager

[Home Manager](https://github.com/nix-community/home-manager) manages *user*
config (dotfiles, per-user packages) the way NixOS manages the system.
`home-manager/home.nix` is exposed as a standalone config
(`homeConfigurations."<user>@atlas"`), applied with
`home-manager switch --flake .#<user>@atlas`. Some dotfiles here are still kept
in a separate git repo instead, which is fine: you can move things into Home
Manager gradually.

## `modules/`

Empty templates, from the
[starter config](https://github.com/Misterio77/nix-starter-configs) this repo grew
out of. They're for modules with their *own options* that you'd publish for
others. `modules/nixos/` entries are auto-imported on hosts that import
`common/global`. For personal config, `hosts/common/optional/` is the simpler
place.

## Day-to-day workflow

| Task | Command |
|---|---|
| Apply config to this machine | `make switch` |
| Build here, deploy to another machine over SSH | `make switch HOST=<name>` |
| Update all inputs (new package versions) | `make update`, then `make switch` |
| Free disk space from old generations | `make gc`, `make cleanup_generations` |
| Check a config evaluates without building | `nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath` |
| Explore the config interactively | `nix repl`, then `:lf .` |

`make switch` also formats the code (`alejandra`) and, if the build succeeds,
**commits the working tree** with the new generation as the message (the
`NNN date version kernel ...` lines in `git log`). Every live generation then
maps to a commit. Make deliberate commits *before* switching if you want
readable history.

**Rollback:** every switch creates a new generation. If one breaks, pick the
previous one in the boot menu, or run `sudo nixos-rebuild switch --rollback`.

## Making it your own

1. **Fork it**, or better, start from the
   [starter config](https://github.com/Misterio77/nix-starter-configs) and
   borrow pieces from here. This repo has personal choices you probably don't want.
2. **Replace the identity bits:**
   - username, description and SSH `authorizedKeys` in each `configuration.nix`
   - `time.timeZone`, locale, keyboard layout
   - the tailnet name in `hosts/common/optional/known-hosts.nix`
   - `system.autoUpgrade.flake` in `hosts/common/global/auto-upgrade.nix` (points at this repo on GitHub)
3. **Delete the hosts and secrets.** Remove `hosts/atlas`, `hosts/daedalus` and
   `hosts/hermes`, and their entries in `flake.nix`. **You can't decrypt the
   `secrets.yaml` files**; they're encrypted to my key. Remove them, then remove
   or replace the `age` key in `.sops.yaml` with your own (see
   [secrets.md](secrets.md)).
4. **Add your first machine:** copy your own `/etc/nixos/configuration.nix` and
   `hardware-configuration.nix` into `hosts/<yourhost>/`, add a `default.nix`
   that imports them plus `../common/global`, register the host in `flake.nix`,
   and run `sudo nixos-rebuild switch --flake .#<yourhost>`. Then split things
   out into `common/` as a second machine appears. [adding-a-host.md](adding-a-host.md)
   covers the full process.
5. **Keep `system.stateVersion`** at whatever your install generated. It records
   the release a machine was *installed* with, for data-format compatibility. It
   is **not** the version you run, and bumping it doesn't upgrade anything.
