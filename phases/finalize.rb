#
# Helpers
#
include_recipe File.expand_path('../../helpers/normalize', __FILE__)
include_recipe File.expand_path('../../helpers/validate', __FILE__)
#
# Recipes
#
include_recipe File.expand_path('../../cookbooks/golang', __FILE__)
include_recipe File.expand_path('../../cookbooks/desync', __FILE__)
include_recipe File.expand_path('../../cookbooks/zsyncmake2', __FILE__)
include_recipe File.expand_path('../../cookbooks/rootfs_umount', __FILE__)
include_recipe File.expand_path('../../cookbooks/rootfs_archive', __FILE__)
