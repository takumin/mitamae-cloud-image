#
# Helpers
#
include_recipe File.expand_path('../../helpers/normalize', __FILE__)
include_recipe File.expand_path('../../helpers/validate', __FILE__)
#
# Recipes
#
include_recipe File.expand_path('../../cookbooks/extract-vmlinux', __FILE__)
include_recipe File.expand_path('../../cookbooks/rootfs_umount', __FILE__)
include_recipe File.expand_path('../../cookbooks/rootfs_archive', __FILE__)
