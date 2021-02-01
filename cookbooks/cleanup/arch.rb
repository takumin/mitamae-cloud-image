# frozen_string_literal: true

#
# Upgrade Packages
#

execute 'pacman -Syyu --noconfirm'

#
# Cleanup Packages
#

execute 'pacman -Scc --noconfirm'
