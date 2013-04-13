require 'shellwords'

module Dragonfly
  class Shell

    attr_accessor :log_commands

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command)
      escaped_command = escape_args(command)
      log.debug("Running command: #{escaped_command}") if log_commands
      result = `#{escaped_command}`
      raise CommandFailed, "Command failed (#{escaped_command}) with exit status #{$?.exitstatus}" unless $?.success?
      result
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
