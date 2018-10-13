module Fusuma
  # Execute Command
  class CommandExecutor
    def initialize(vector)
      @vector = vector
    end
    attr_reader :vector

    def execute
      pid = fork {
        Process.daemon(true)
        exec("#{command_or_shortcut}")
      }
      Process.detach(pid)
      MultiLogger.info("Execute: #{command_or_shortcut}")
    end

    private

    def command_or_shortcut
      @command_or_shortcut ||= command || shortcut || no_command
    end

    def command
      Config.command(vector)
    end

    def shortcut
      s = Config.shortcut(vector)
      return unless s

      c = "xdotool key #{s}"
      MultiLogger.warn 'shortcut property is deprecated.'
      MultiLogger.warn "Use command: #{c} instead of shortcut: #{s}"
      c
    end

    def no_command
      "echo \"Command is not assigned #{config_parameters}\""
    end

    def config_parameters
      {
        gesture: vector.class::TYPE,
        finger: vector.finger,
        direction: vector.direction
      }
    end
  end
end
