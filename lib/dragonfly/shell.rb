require 'shellwords'
begin
  require 'fiber'
rescue LoadError => e
  #
end

module Dragonfly
  module Shell
    
    include Configurable
    configurable_attr :log_commands, false
    configurable_attr :async, false

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command, args="")
      full_command = "#{command} #{escape_args(args)}"
      log.debug("Running command: #{full_command}") if log_commands
      begin
        result, status = async ? async_command(full_command) : sync_command(full_command)
      rescue Errno::ENOENT
        raise_shell_command_failed(full_command)
      end
      if status.exitstatus == 1
        throw :unable_to_handle
      elsif !status.success?
        raise_shell_command_failed(full_command)
      end
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
    
    def sync_command(command)
      [`#{command}`, $?]
    end
    
    def async_command(command)
      f = Fiber.current
      EM.system command do |result, status|
        f.resume [result, status]
      end
      Fiber.yield
    end

  end
end
