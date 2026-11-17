# Managing secrets

**This repo is public.** Secrets are committed only in encrypted form, using
[sops](https://github.com/getsops/sops) with [age](https://age-encryption.org)
keys, and decrypted on each host at activation time by
[sops-nix](https://github.com/Mic92/sops-nix).

## How it's set up

- **`.sops.yaml`**: lists the age *public* keys allowed to decrypt, and which
  files they apply to. Any path ending in `secrets/secrets.yaml` is encrypted to
  the `primary` key.
- **`hosts/<name>/secrets/secrets.yaml`**: one encrypted YAML file per host.
  Each value looks like `ENC[AES256_GCM,data:...]`.
- **The age private key** lives at `~/.config/sops/age/keys.txt` on each host
  that uses secrets, and is **never** committed. Hosts point sops-nix at it:

  ```nix
  imports = [ inputs.sops-nix.nixosModules.sops ];
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/<you>/.config/sops/age/keys.txt";
  ```

`sops` itself is installed on hosts that import `common/optional/dev.nix`.

## What's public and what isn't

| Visible to anyone | Stays private |
|---|---|
| Secret **names** (YAML keys are plaintext) | Secret **values** |
| Which hosts have secrets, and how many | The age private key |
| The age **public** key in `.sops.yaml` | |
| Where each secret is used in the Nix config | |

So **pick names that don't leak information themselves**. `ts-authkey` is fine;
a name that contains a real address, username or account ID is not.

## Everyday use

**Edit or add secrets.** This decrypts into `$EDITOR` and re-encrypts on save.
Run it from the repo root so `.sops.yaml` is picked up:

```bash
sops hosts/<name>/secrets/secrets.yaml
```

The same command creates the file for a new host (`mkdir -p hosts/<name>/secrets` first).

**Use a secret in config.** Declare it, then reference the decrypted file's path.
The value never enters the Nix store:

```nix
sops.secrets.restic-password = {
  owner = "restic";      # default is root, mode 0400
};

services.restic.server.passwordFile = config.sops.secrets.restic-password.path;
```

At runtime the decrypted value is at `/run/secrets/<name>`. Only pass `.path` to
options that take a *file*. Never interpolate a secret's contents into a Nix
string: anything in a Nix string ends up world-readable in `/nix/store`.

**Read one value** (prints to your terminal only):

```bash
sops --decrypt --extract '["ts-authkey"]' hosts/<name>/secrets/secrets.yaml
```

## Rules for a public repo

1. **Never write decrypted output into the repo tree.** No
   `sops -d ... > something.yaml` inside the checkout. Use `sops <file>` to edit
   in place.
2. **Never commit `keys.txt`** or any `AGE-SECRET-KEY-...` line.
3. **Check before committing a secrets file.** Every value should be `ENC[...]`:
   ```bash
   git diff --cached -- '*secrets.yaml' | grep '^+' | grep -v -e 'ENC\[' -e '^+++' -e 'sops:' -e '^+    '
   ```
   No output means no plaintext top-level value was added. The indented
   `sops:` metadata block is skipped. It doesn't inspect nested keys, so if you
   nest secrets, eyeball `git diff --cached` too.
4. **A leaked plaintext secret stays in git history forever, even after a
   follow-up commit removes it.** Rotate the secret itself (new password, new
   token). Don't just delete it from the file.

## Setting up a new host

1. Copy the age private key to the host, owned by you with mode 600:
   ```bash
   scp ~/.config/sops/age/keys.txt <host>:.config/sops/age/keys.txt   # mkdir -p first
   ssh <host> chmod 600 ~/.config/sops/age/keys.txt
   ```
2. Add the `sops.*` lines above to the host's `configuration.nix`, and create
   `hosts/<name>/secrets/secrets.yaml` with `sops`.
3. `make switch HOST=<name>`.

> **Gotcha: a separate `/home` filesystem.** sops-nix decrypts during system
> activation, which runs before non-essential filesystems are mounted at boot.
> On a host where `/home` is its own partition or subvolume (hermes's disko
> layout has an `@home` subvolume), a key under `/home` isn't there yet, and
> secrets fail to decrypt on boot. Either keep the key outside `/home`:
> ```nix
> sops.age.keyFile = "/var/lib/sops-nix/key.txt";
> ```
> or mark the mount as needed at boot: `fileSystems."/home".neededForBoot = true;`.

## Rotating or adding keys

- **New key, or a second machine's key, allowed to decrypt:** add the public key
  to `.sops.yaml`, then re-encrypt each file to the new key set:
  ```bash
  sops updatekeys hosts/<name>/secrets/secrets.yaml
  ```
- **The private key leaked:** generate a new one (`age-keygen -o keys.txt`),
  update `.sops.yaml`, run `updatekeys` on every file, **and rotate every secret
  value**. Old ciphertext in git history is still readable with the old key.

### Possible improvement: per-host keys

Right now one personal age key decrypts everything, and it has to be copied to
every host by hand. sops-nix can instead derive each host's age key from its SSH
host key (`sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]`, public key
via `ssh-to-age < hosts/<name>/ssh_host_ed25519_key.pub`). Each host could then
decrypt only its own file, with no extra key to copy, and the host key is
already generated during install (see [adding-a-host.md](adding-a-host.md)).
