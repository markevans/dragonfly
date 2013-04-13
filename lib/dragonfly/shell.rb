require 'shellwords'

module Dragonfly
  class Shell

    attr_accessor :log_commands

    # Exceptions
    class CommandFailed < RuntimeError; end
    class CommandNotFound < RuntimeError; end

    def run(command, args="")
      full_command = "#{command} #{escape_args(args)}"
      log.debug("Running command: #{full_command}") if log_commands
      begin
        result = `#{full_command}`
      rescue Errno::ENOENT
        raise CommandNotFound, "Command #{command.inspect} not found"
      end
      raise CommandFailed, "Command failed (#{full_command}) with exit status #{$?.exitstatus}" unless $?.success?
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
