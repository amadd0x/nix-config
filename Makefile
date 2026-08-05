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

switch_atlas:
	alejandra .
	@git diff -U0
	@sudo nixos-rebuild switch --flake .#atlas > atlas-switch.log || (cat atlas-switch.log | grep --color error && false)
	@echo -e "\nBuild success. Commiting generation to git"
	@$(call commit_generation,nixos-rebuild list-generations)

switch_daedalus:
	alejandra .
	@git diff -U0
	@nixos-rebuild --flake .#daedalus --target-host amaddox@daedalus --sudo switch &>daedalus-switch.log || (cat daedalus-switch.log | grep --color error && false)
	@echo -e "\nBuild success. Commiting generation to git"
	@$(call commit_generation,ssh amaddox@daedalus nixos-rebuild list-generations)

switch_hermes:
	alejandra .
	@git diff -U0
	@sudo nixos-rebuild switch --flake .#hermes > hermes-switch.log || (cat hermes-switch.log | grep --color error && false)
	@echo -e "\nBuild success. Commiting generation to git"
	@$(call commit_generation,nixos-rebuild list-generations)

verify_and_repair: gc
	sudo nix-store --verify --check-contents --repair

update: gc
	@nix flake update
	@nix flake update nixpkgs-unstable

gc:
	nix-collect-garbage

cleanup_generations:
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 30d
