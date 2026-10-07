#
# Private Variables
#

target_name = []
target_name << node.target.distribution
target_name << node.target.suite if node.target.distribution.match(/^(?:debian|ubuntu)$/)
target_name << node.target.kernel
target_name << node.target.architecture
target_name << node.target.role

case node.target.distribution
when 'debian'
  components = ['main', 'contrib', 'non-free', 'non-free-firmware']
when 'ubuntu'
  components = ['main', 'restricted', 'universe', 'multiverse']
end

#
# Public Variables
#

node.reverse_merge!({
  target: {
    components: components,
    directory:  "/var/lib/mitamae-cloud-image/#{target_name.join('-')}",
    tmpfs:      ENV['DISABLE_TARGET_TMPFS'] != 'true',
  },
})
