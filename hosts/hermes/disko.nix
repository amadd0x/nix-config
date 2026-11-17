# Whole-disk layout for hermes: EFI + LUKS-encrypted btrfs.
#
#   nvme0n1
#   ├─ ESP   1G  vfat  -> /boot
#   └─ LUKS  rest      -> "cryptroot"
#        └─ btrfs
#             ├─ @root -> /
#             ├─ @home -> /home
#             ├─ @nix  -> /nix
#             └─ @swap -> /.swapvol (swapfile, also usable for hibernate)
#
# WARNING: applying this (via nixos-anywhere or `disko --mode destroy,format,mount`)
# ERASES THE WHOLE DISK, Windows included.
#
# During install the LUKS passphrase is read from /tmp/secret.key on the target;
# nixos-anywhere copies it there with `--disk-encryption-keys /tmp/secret.key <local-file>`.
# After install you type the passphrase at boot.
{
  disko.devices.disk.main = {
    type = "disk";
    # VERIFY on hermes with `lsblk` before installing.
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["fmask=0077" "dmask=0077"];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/secret.key";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "16G";
                };
              };
            };
          };
        };
      };
    };
  };
}
