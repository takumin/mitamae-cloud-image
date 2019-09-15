PROFILE_YAML    ?= profiles/ubuntu/bionic/generic/amd64/server.yml

MITAMAE_REPOS   ?= github.com/itamae-kitchen/mitamae
MITAMAE_RELEASE ?= 1.9.0
MITAMAE_ARCH    ?= $(shell uname -m)
MITAMAE_URL     ?= https://$(MITAMAE_REPOS)/releases/download/v$(MITAMAE_RELEASE)/mitamae-$(MITAMAE_ARCH)-linux

ifneq (,${TARGET_DIRECTORY})
MITAMAE_ENV += TARGET_DIRECTORY="${TARGET_DIRECTORY}"
endif

ifneq (,${APT_REPO_URL_UBUNTU})
MITAMAE_ENV += APT_REPO_URL_UBUNTU="${APT_REPO_URL_UBUNTU}"
endif

.PHONY: all
all: bootstrap

.PHONY: mitamae
mitamae: .bin/mitamae
.bin/mitamae:
	@mkdir -p "$(dir $@)"
	@if [ "$(subst MItamae v,,$(shell mitamae version))" != "$(MITAMAE_RELEASE)" ]; then \
		rm -f "$@"; \
	fi
	@if [ ! -f "$@" ]; then \
		curl -fsSL -o "$@" "$(MITAMAE_URL)"; \
	fi
	@if [ ! -x "$@" ]; then \
		chmod +x "$@"; \
	fi

.PHONY: require
require: mitamae
	@sudo $(MITAMAE_ENV) .bin/mitamae local -y $(PROFILE_YAML) phases/require.rb

.PHONY: bootstrap
bootstrap: require
	@sudo $(MITAMAE_ENV) .bin/mitamae local -y $(PROFILE_YAML) phases/bootstrap.rb
