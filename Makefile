# Commit the generation that is now live on the deployed host.
# $(1) is a shell command that prints that host's list-generations output.
#
# Uses $$(...) rather than make's $(shell ...): make expands a whole recipe
# before running any of its lines, so $(shell ...) would query the generation
# *before* the switch and record the previous one.
define commit_generation
gen="$$($(1) | grep True | awk '{$$1=$$1};1')"; \
if git diff --quiet HEAD; then \
	echo "Nothing to commit; working tree is clean."; \
else \
	git commit -am "$$gen"; \
fi
endef

SHELL := bash
.SHELLFLAGS := -o pipefail -c

# Host to deploy. Defaults to the machine you're on.
HOST ?= $(shell hostname)
# Remote hosts whose sudo needs a password (prompted once by nixos-rebuild).
ASK_SUDO_HOSTS := hermes

# `make switch`              -> rebuild this machine
# `make switch HOST=hermes`  -> build here, deploy to hermes over ssh (tailnet)
switch:
	alejandra .
	@git diff -U0
	@if [ "$(HOST)" = "$$(hostname)" ]; then \
		sudo nixos-rebuild switch --flake .#$(HOST); \
	else \
		nixos-rebuild switch --flake .#$(HOST) --target-host amaddox@$(HOST) --sudo \
			$(if $(filter $(HOST),$(ASK_SUDO_HOSTS)),--ask-sudo-password); \
	fi 2>&1 | tee $(HOST)-switch.log
	@echo -e "\nBuild success. Commiting generation to git"
	@if [ "$(HOST)" = "$$(hostname)" ]; then \
		$(call commit_generation,nixos-rebuild list-generations); \
	else \
		$(call commit_generation,ssh amaddox@$(HOST) nixos-rebuild list-generations); \
	fi

# Shortcuts kept for muscle memory
switch_atlas:
	@$(MAKE) --no-print-directory switch HOST=atlas
switch_daedalus:
	@$(MAKE) --no-print-directory switch HOST=daedalus
switch_hermes:
	@$(MAKE) --no-print-directory switch HOST=hermes

# Fresh install of hermes from atlas (ERASES THE DISK). See docs/adding-a-host.md.
#   make install_hermes TARGET=root@<installer-ip> LUKS_KEY=/path/to/passphrase-file
# Default kexecs into nixos-anywhere's installer first, which is required when the
# target runs from the disk being wiped. That image has no Wi-Fi, so on Wi-Fi boot
# the target from a live USB instead and pass PHASES=disko,install to skip kexec.
# Never skip kexec when the target is running from its own disk.
PHASES ?= kexec,disko,install
install_hermes:
	@test -n "$(TARGET)" || { echo "Set TARGET=root@<installer-ip>"; false; }
	@test -f "$(LUKS_KEY)" || { echo "Set LUKS_KEY=<file containing the LUKS passphrase>"; false; }
	nix run github:nix-community/nixos-anywhere -- \
		--flake .#hermes \
		--target-host $(TARGET) \
		--disk-encryption-keys /tmp/secret.key $(LUKS_KEY) \
		--generate-hardware-config nixos-generate-config ./hosts/hermes/hardware-configuration.nix \
		--phases $(PHASES) \
		$(if $(EXTRA_FILES),--extra-files $(EXTRA_FILES))
	@echo -e "\nInstalled. Set amaddox's password, then reboot:"
	@echo "  ssh -t $(TARGET) nixos-enter --root /mnt -c \"'passwd amaddox'\""
	@echo "  ssh $(TARGET) reboot"

verify_and_repair: gc
	sudo nix-store --verify --check-contents --repair

update: gc
	@nix flake update
	@nix flake update nixpkgs-unstable

gc:
	nix-collect-garbage

cleanup_generations:
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 30d
