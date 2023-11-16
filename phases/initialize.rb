#
# Phase
#
node[:phase] = :initialize
#
# Helpers
#
include_recipe File.expand_path('../../helpers/normalize', __FILE__)
include_recipe File.expand_path('../../helpers/validate', __FILE__)
include_recipe File.expand_path('../../helpers/messages', __FILE__)
#
# Recipes
#
include_recipe File.expand_path('../../cookbooks/debootstrap', __FILE__)
include_recipe File.expand_path('../../cookbooks/archbootstrap', __FILE__)
include_recipe File.expand_path('../../cookbooks/rootfs_mount', __FILE__)
include_recipe File.expand_path('../../cookbooks/resolv_conf', __FILE__)
include_recipe File.expand_path('../../cookbooks/mitamae', __FILE__)
