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
  Open3.popen3(command.join(' ')) do |stdin, stdout, stderr, wait_thr|
    stdin.close_write

    begin
      loop do
        IO.select([stdout, stderr]).flatten.compact.each do |io|
          io.each do |line|
            next if line.nil? || line.empty?
            puts line
          end
        end
        break if stdout.eof? && stderr.eof?
      end
    rescue EOFError
    end
  end
end
