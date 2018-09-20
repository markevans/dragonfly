require 'shellwords'
require 'open3'
require 'dragonfly'

module Dragonfly
  class Shell

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command)
      command.flatten!
      command.compact!

      Dragonfly.debug("shell command: #{command.join(' ')}")
      run_command(command)
    end

    private

    def run_command(command)
      stdout_str, stderr_str, status = Open3.capture3(*command)

      raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus} and stderr #{stderr_str}" unless status.success?
      stdout_str
    end

  end
end
