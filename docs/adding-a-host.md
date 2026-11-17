# Adding a host

Every machine is a `nixosConfigurations.<name>` entry in `flake.nix`, built from
`hosts/<name>/`. A new host takes four steps: write its config, give it an SSH
host key, install it, and deploy to it from then on with `make switch`.

## 1. Write the config

```
hosts/<name>/
├── default.nix                  # entrypoint: imports + host-specific packages
├── configuration.nix            # hostname, bootloader, users, desktop, stateVersion
├── hardware-configuration.nix   # generated on the machine (see step 3)
├── disko.nix                    # optional: declarative disk layout for nixos-anywhere
├── ssh_host_ed25519_key.pub     # required, see step 2
└── secrets/secrets.yaml         # optional, see secrets.md
```

The easiest start is to copy `hosts/hermes/`. It's the most recent host and has
disko, Tailscale and the shared dev tooling wired in. In `default.nix`, import:

- `../common/global`: Home Manager, auto-upgrade, hardened OpenSSH, pinned
  known_hosts, overlays. Every host should import it.
- `../common/optional/*`: opt-in pieces (`dev.nix`, `tailscale.nix`, ...).

In `configuration.nix`, set at least:

```nix
networking.hostName = "<name>";
system.stateVersion = "<release you install with>";  # never change it afterwards
users.users.<you>.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
```

Then register the host in `flake.nix`:

```nix
<name> = lib.nixosSystem {
  specialArgs = {inherit inputs outputs;};
  modules = [./hosts/<name>];
};
```

Check that it evaluates before touching any hardware:

```bash
nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath
```

## 2. Give it an SSH host key

`hosts/common/optional/known-hosts.nix` pins the host key of **every** host in
`nixosConfigurations` into every other host's `/etc/ssh/ssh_known_hosts`, reading
`hosts/<name>/ssh_host_ed25519_key.pub`. If that file is missing, **no host will
evaluate**, not even the existing ones.

Generate the key pair before installing, so the host has its final identity from
first boot:

```bash
mkdir -p ~/<name>-extra/etc/ssh
ssh-keygen -t ed25519 -N "" -C "root@<name>" -f ~/<name>-extra/etc/ssh/ssh_host_ed25519_key
cp ~/<name>-extra/etc/ssh/ssh_host_ed25519_key.pub hosts/<name>/
```

Commit only the `.pub` file. The private key goes onto the machine during install
(`EXTRA_FILES`, step 3) and should not stay anywhere else afterwards.

For a **reinstall**, copy the existing `/etc/ssh/ssh_host_ed25519_key{,.pub}` (and
`/var/lib/tailscale` to keep the same tailnet node) off the old machine instead.
Check permissions before installing. Copying through a FAT/exFAT USB stick
resets everything to 755, and sshd then refuses the private key:

```bash
chmod 600 ~/<name>-extra/etc/ssh/ssh_host_ed25519_key
chmod 700 ~/<name>-extra/var/lib/tailscale
find ~/<name>-extra/var/lib/tailscale -type f -exec chmod 600 {} +
```

## 3. Install

### Option A: nixos-anywhere from another host (recommended)

Partitions the disk from `disko.nix`, installs the flake config, and copies
`EXTRA_FILES` into place, all over SSH. `make install_hermes` wraps it; for a
new host, copy that target and change `.#hermes` and the hardware-config path.

**1. Boot the target from a live USB.**

- Write the ISO **raw** (`dd`, Rufus in DD mode, Etcher). **Ventoy does not
  work:** the ISO can't find its own Nix store and drops into emergency mode
  (`sysroot-nix-.ro\x2dstore.mount` failed).
- Prefer the **minimal** ISO: it runs sshd out of the box. The graphical ISO may
  ship without an sshd unit (see troubleshooting).

**2. Let the installing host in as root.** Key auth is the most reliable.
GitHub publishes every account's public keys at `https://github.com/<user>.keys`:

```bash
# on the target (live USB)
sudo mkdir -p /root/.ssh
curl -fsSL https://github.com/<user>.keys | sudo tee /root/.ssh/authorized_keys
sudo chmod 700 /root/.ssh && sudo chmod 600 /root/.ssh/authorized_keys
ip -br a        # note the IP
```

Check from the installing host with `ssh root@<ip> true`.

**3. Run the install.**

```bash
printf '%s' 'your-luks-passphrase' > /tmp/<name>-luks.key && chmod 600 /tmp/<name>-luks.key

make install_hermes TARGET=root@<ip> LUKS_KEY=/tmp/<name>-luks.key \
  EXTRA_FILES=~/<name>-extra PHASES=disko,install

shred -u /tmp/<name>-luks.key
```

Use `printf`, not `echo`: a trailing newline becomes part of the passphrase.

> **`PHASES` and kexec.** By default nixos-anywhere first *kexecs* the target
> into its own RAM-only installer, so the disk can be wiped while nothing runs
> from it. That image only does wired DHCP, so a target on Wi-Fi drops off
> the network and the install hangs on `Connection timed out`.
>
> - Target booted from a **live USB**: pass `PHASES=disko,install` (skips kexec).
> - Target running from **its own disk** (an existing install): keep the default
>   (`kexec,disko,install`) and use Ethernet. **Never skip kexec here.** disko
>   would wipe the disk the running system is on and leave it half-partitioned.

**4. Before rebooting:** check the restored key landed with the right owner and
mode, set a login password, and reboot without the USB stick.

```bash
ssh root@<ip> ls -l /mnt/etc/ssh/ssh_host_ed25519_key       # -rw------- root
ssh -t root@<ip> nixos-enter --root /mnt -c 'passwd <you>'
ssh root@<ip> reboot
```

nixos-anywhere also rewrote `hosts/<name>/hardware-configuration.nix` in this
repo. Commit it.

### Option B: the ISO's own installer

Install normally, then copy `/etc/nixos/hardware-configuration.nix` into
`hosts/<name>/` and switch to the flake (step 4). Simpler, but disko isn't used,
so the disk layout lives only in the generated hardware config.

## 4. After first boot

1. Unlock LUKS, log in, join Wi-Fi (`nmtui` or the desktop).
2. If the host keeps a sudo password, add it to `ASK_SUDO_HOSTS` in the Makefile.
3. Deploy from then on:

   ```bash
   make switch HOST=<name>     # build here, deploy over SSH
   make switch                 # on the host itself
   ```

   `make switch` commits the resulting generation to git.
4. If the host uses secrets, set up its age key: see [secrets.md](secrets.md).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Live USB boots to "You are in emergency mode" | Written with Ventoy. Write the ISO raw with `dd`. |
| `Unit sshd.service not found` on the live ISO | ISO ships without sshd. Use the minimal ISO, or start it by hand (below). |
| `Connection timed out` but the target answers ping | Firewall on the live ISO: `sudo systemctl stop firewall`. Or the kexec image lost Wi-Fi: see `PHASES` above. |
| `Too many authentication failures` | Your agent offers more keys than sshd's `MaxAuthTries` (6). Raise it on the target, or `ssh -o IdentitiesOnly=yes -i <key>`. |
| Root password rejected by a hand-started sshd | No PAM config for sshd on that ISO. Use key auth (GitHub keys above). |
| `error: path '.../ssh_host_ed25519_key.pub' does not exist` on every host | A host in the flake has no `.pub` file. See step 2. |
| "REMOTE HOST IDENTIFICATION HAS CHANGED" for the target IP | Live ISO and kexec image use throwaway host keys: `ssh-keygen -R <ip>`. |

Starting sshd by hand on a live ISO without the unit:

```bash
SSHD=$(dirname "$(readlink -f "$(which ssh)")")/sshd
sudo ssh-keygen -A
grep -q '^sshd:' /etc/passwd || sudo useradd -r -d /var/empty -s /run/current-system/sw/bin/nologin sshd
sudo mkdir -p /var/empty
sudo systemctl stop firewall
sudo "$SSHD" -D -e -f /dev/null -o PermitRootLogin=yes -o MaxAuthTries=30   # keep this terminal open
```
