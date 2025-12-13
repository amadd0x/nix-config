switch_atlas:
	alejandra .
	@git diff -U0
	@sudo nixos-rebuild switch --flake .#atlas > atlas-switch.log || (cat atlas-switch.log | grep --color error && false)
	@echo -e "\nBuild success. Commiting generation to git"
	@gen="$(shell nixos-rebuild --flake .#atlas list-generations | grep True | awk '{$$1=$$1};1')"; \
	git commit -am "$$gen"

switch_daedalus:
	alejandra .
	@git diff -U0
	@nixos-rebuild --flake .#daedalus --target-host amaddox@daedalus --use-remote-sudo switch &>daedalus-switch.log || (cat daedalus-switch.log | grep --color error && false)
	@echo -e "\nBuild success. Commiting generation to git"
	@gen="$(shell nixos-rebuild --flake .#daedalus --target-host amaddox@daedalus --use-remote-sudo list-generations | grep current | awk '{$$1=$$1};1')"; \
	git commit -am "$$gen"

switch_hermes:
	alejandra .
	@git diff -U0
	@sudo nixos-rebuild switch --flake .#hermes > hermes-switch.log || (cat hermes-switch.log | grep --color error && false)
	@echo -e "\nBuild success. Commiting generation to git"
	@gen="$(shell nixos-rebuild --flake .#hermes list-generations | grep current | awk '{$$1=$$1};1')"; \
	git commit -am "$$gen"

verify_and_repair: gc
	sudo nix-store --verify --check-contents --repair

update: gc
	@nix flake update

gc:
	nix-collect-garbage

cleanup_generations:
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 30d
