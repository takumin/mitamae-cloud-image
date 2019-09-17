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

ifneq (,${APT_REPO_URL_UBUNTU_PORTS})
MITAMAE_ENV += APT_REPO_URL_UBUNTU_PORTS="${APT_REPO_URL_UBUNTU_PORTS}"
endif

ifneq (,${APT_REPO_URL_DEBIAN})
MITAMAE_ENV += APT_REPO_URL_DEBIAN="${APT_REPO_URL_DEBIAN}"
endif

ifneq (,${APT_REPO_URL_DEBIAN_SECURITY})
MITAMAE_ENV += APT_REPO_URL_DEBIAN_SECURITY="${APT_REPO_URL_DEBIAN_SECURITY}"
endif

.PHONY: all
all: finalize

.PHONY: mitamae
mitamae: .bin/mitamae
.bin/mitamae:
	@mkdir -p "$(dir $@)"
	@if [ ! -f "$@" ]; then \
		curl -fsSL -o "$@" "$(MITAMAE_URL)"; \
	fi
	@if [ ! -x "$@" ]; then \
		chmod +x "$@"; \
	fi

.PHONY: initialize
initialize: mitamae
	@sudo $(MITAMAE_ENV) .bin/mitamae local -y $(PROFILE_YAML) phases/initialize.rb

.PHONY: build
build: initialize
	@sudo $(MITAMAE_ENV) .bin/mitamae local -y $(PROFILE_YAML) phases/build.rb

.PHONY: finalize
finalize: build
	@sudo $(MITAMAE_ENV) .bin/mitamae local -y $(PROFILE_YAML) phases/finalize.rb
