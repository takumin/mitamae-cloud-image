# frozen_string_literal: true

require 'open3'

cookbooks_dir = File.join(__dir__, 'cookbooks')
variables_dir = File.join(__dir__, 'variables')

recipes = [
  File.join(cookbooks_dir, 'debootstrap', 'default.rb')
]

command = ['mitamae', 'local']

desc 'ubuntu/amd64/bionic/generic/server'
task :ubuntu_amd64_bionic_generic_server do
  command.concat(['-y', File.join(variables_dir, 'ubuntu', 'amd64', 'bionic', 'generic', 'server.yml')])
  command.concat(recipes)
  stdout, stderr, status = Open3.capture3(command.join(' '))
  puts stdout
  puts stderr
  puts status
end
