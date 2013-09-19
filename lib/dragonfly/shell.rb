require 'shellwords'
require 'open3'
require 'dragonfly'

module Dragonfly
  class Shell

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command, opts={})
      command = escape_args(command) unless opts[:escape] == false
      Dragonfly.debug("shell command: #{command}")
      Open3.popen3 command do |stdin, stdout, stderr, wait_thread|
        status = wait_thread.value
        raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus} and stderr #{stderr.read}" unless status.success?
        stdout.read
      end
    end

    def escape_args(args)
      args.shellsplit.map do |arg|
        quote arg.gsub(/\\?'/, %q('\\\\''))
      end.join(' ')
    end

    def quote(string)
      q = Dragonfly.running_on_windows? ? '"' : "'"
      q + string + q
    end

  end
end
