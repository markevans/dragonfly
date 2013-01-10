require 'shellwords'

module Dragonfly
  class Shell
    
    attr_accessor :log_commands

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command, args="")
      full_command = "#{command} #{escape_args(args)}"
      log.debug("Running command: #{full_command}") if log_commands
      begin
        result = `#{full_command}`
      rescue Errno::ENOENT
        raise_shell_command_failed(full_command)
      end
      raise_shell_command_failed(full_command) unless $?.success?
      result
    end
  
    def raise_shell_command_failed(command)
      raise CommandFailed, "Command failed (#{command}) with exit status #{$?.exitstatus}"
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
