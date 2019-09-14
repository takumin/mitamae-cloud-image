MITAMAE_REPOS   ?= github.com/itamae-kitchen/mitamae
MITAMAE_RELEASE ?= 1.9.0
MITAMAE_ARCH    ?= $(shell uname -m)
MITAMAE_URL     ?= https://$(MITAMAE_REPOS)/releases/download/v$(MITAMAE_RELEASE)/mitamae-$(MITAMAE_ARCH)-linux

.PHONY: all
all: $(CURDIR)/.bin/mitamae ubuntu-bionic-generic-amd64-server

.PHONY: ubuntu-bionic-generic-amd64-server
ubuntu-bionic-generic-amd64-server:
	@$(CURDIR)/.bin/mitamae local -y "$(CURDIR)/profiles/$(subst -,/,$@).yml" "$(CURDIR)/cookbooks/debootstrap/default.rb"

.PHONY: $(CURDIR)/.bin/mitamae
$(CURDIR)/.bin/mitamae:
	@mkdir -p "$(dir $@)"
	@if [ "$(subst MItamae v,,$(shell mitamae version))" != "$(MITAMAE_RELEASE)" ]; then \
		rm "$@"; \
	fi
	@if [ ! -f "$@" ]; then \
		curl -fsSL -o "$@" "$(MITAMAE_URL)"; \
	fi
	@if [ ! -x "$@" ]; then \
		chmod +x "$@"; \
	fi
