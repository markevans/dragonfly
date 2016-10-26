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
      args.shellsplit.map do |arg|
        quote arg.gsub(/\\?'/, %q('\\\\''))
      end.join(' ')
    end

    def quote(string)
      q = Dragonfly.running_on_windows? ? '"' : "'"
      q + string + q
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
        Open3.popen3 command do |stdin, stdout, stderr, wait_thread|
          stdin.close_write # make sure it doesn't hang
          status = wait_thread.value
          raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus} and stderr #{stderr.read}" unless status.success?
          stdout.read
        end
      end

    end

  end
end
