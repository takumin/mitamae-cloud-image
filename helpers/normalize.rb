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
  if node.target.suite.match(/(?:buster|bullseye)/)
    components = ['main', 'contrib', 'non-free']
  else
    components = ['main', 'contrib', 'non-free', 'non-free-firmware']
  end
when 'ubuntu'
  components = ['main', 'restricted', 'universe', 'multiverse']
end

#
# Public Variables
#

node.reverse_merge!({
  target: {
    components: components,
    directory:  "/tmp/#{target_name.join('-')}",
  },
})
