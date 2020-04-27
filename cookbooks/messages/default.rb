#
# Show Variables
#

MItamae.logger.info "Cloud Image Infomation"
MItamae.logger.info "  Distribution: #{node[:target][:distribution]}"
MItamae.logger.info "  Architecture: #{node[:target][:architecture]}"
MItamae.logger.info "  Suite:        #{node[:target][:suite]}"
MItamae.logger.info "  Role:         #{node[:target][:role]}"
MItamae.logger.info "  Target Dir:   #{node[:target][:directory]}"
