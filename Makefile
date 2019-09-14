.PHONY: all
all: ubuntu-bionic-generic-amd64-server

.PHONY: ubuntu-bionic-generic-amd64-server
ubuntu-bionic-generic-amd64-server:
	@mitamae local -y $(CURDIR)/profiles/$(subst -,/,$@).yml $(CURDIR)/cookbooks/debootstrap/default.rb
