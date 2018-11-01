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
      run_command(command)
    end

    def escape_args(args)
      args.shellsplit.map{|arg| escape(arg) }.join(' ')
    end

    def escape(string)
      Shellwords.escape(string)
    end

    private

    # Annoyingly, Open3 seems buggy on jruby:
    # Some versions don't yield a wait_thread in the block and
    # you can't run sub-shells (if explicitly turning shell-escaping off)
    if RUBY_PLATFORM == 'java'

      # Unfortunately we have no control over stderr this way
      def run_command(command)
        result = `#{command}`
        status = $?
        raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus}" unless status.success?
        result
      end

    else

      def run_command(command)
        stdout_str, stderr_str, status = Open3.capture3(command)
        raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus} and stderr #{stderr_str}" unless status.success?
        stdout_str
      end

    end

  end
end
