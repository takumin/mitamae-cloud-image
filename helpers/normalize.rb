#
# Private Variables
#

target_name = []
target_name << node.target.distribution
target_name << node.target.suite if node.target.distribution.match(/^(?:debian|ubuntu)$/)
target_name << node.target.kernel
target_name << node.target.architecture
target_name << node.target.role

#
# Public Variables
#

node.reverse_merge!({
  target: {
    directory: "/tmp/#{target_name.join('-')}",
  },
})
