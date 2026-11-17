# Pin every host's SSH host key (hosts/<name>/ssh_host_ed25519_key.pub) in
# /etc/ssh/ssh_known_hosts, under each name we reach it by.
{
  outputs,
  lib,
  ...
}: let
  tailnet = "moose-tailor.ts.net";
  extraNames = {
    daedalus = ["192.168.0.112"];
  };
in {
  programs.ssh.knownHosts =
    builtins.mapAttrs
    (name: _: {
      hostNames = [name "${name}.${tailnet}"] ++ (extraNames.${name} or []);
      publicKeyFile = ../../${name}/ssh_host_ed25519_key.pub;
    })
    outputs.nixosConfigurations;
}
