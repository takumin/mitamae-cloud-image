# frozen_string_literal: true

require 'open3'

module MitamaeCloudImage
  module Shell
    module_function

    # Runs cmd with a shell, printing its output as it arrives, and returns
    # whether it succeeded
    def run(cmd, chroot: nil)
      retval = false

      # https://ikm.hatenablog.jp/entry/2014/11/12/003925
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
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
        rescue Interrupt
          kill_chroot_processes(chroot) if chroot
          raise
        end

        retval = wait_thr.value.success?
      end

      retval
    end

    # apt-get and dpkg ignore SIGINT while installing, so Ctrl-C leaves them
    # running in the chroot and keeps the target directory busy
    def kill_chroot_processes(dir)
      script = 'for p in /proc/[0-9]*; do [ "$(readlink "$p/root")" = "$1" ] && echo "${p#/proc/}"; done'

      %w{TERM KILL}.each do |signal|
        20.times do
          pids = Open3.capture2('sudo', 'sh', '-c', script, 'sh', File.expand_path(dir))[0].split
          return if pids.empty?
          system('sudo', 'kill', "-#{signal}", *pids, err: File::NULL)
          sleep 0.5
        end
      end
    end
  end
end
