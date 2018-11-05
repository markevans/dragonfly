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

    def escape(string)
      Shellwords.escape(string)
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
        raise_command_failed!(command, status.exitstatus) unless status.success?
        result
      rescue Errno::ENOENT => e
        raise_command_failed!(command, nil, e.message)
      end

    else

      def run_command(command)
        stdout_str, stderr_str, status = Open3.capture3(command)
        raise_command_failed!(command, status.exitstatus, stderr_str) unless status.success?
        stdout_str
      rescue Errno::ENOENT => e
        raise_command_failed!(command, nil, e.message)
      end

    end

    def raise_command_failed!(command, status=nil, error=nil)
      raise CommandFailed, [
        "Command failed: #{command}",
        ("exit status: #{status}" if status),
        ("error: #{error}" if error),
      ].join(', ')
    end

  end
end
