require 'shellwords'
require 'open3'
require 'dragonfly'

module Dragonfly
  class Shell

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command, opts={})
      if command.is_a? Array
        command.flatten!
        command.compact!
      else # Legacy string-based command support
        warn '[DEPRECATION] String based commands are deprecated. Please pass commands as Arrays instead.'
        command = escape_args(command) unless opts[:escape] == false
        command = [command]
      end

      Dragonfly.debug("shell command: #{command.join(' ')}")
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

    def run_command(command)
      stdout_str, stderr_str, status = Open3.capture3(*command)

      raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus} and stderr #{stderr_str}" unless status.success?
      stdout_str
    end

  end
end
