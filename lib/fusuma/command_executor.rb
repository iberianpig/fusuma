module Fusuma
  # Execute Command
  class CommandExecutor
    def initialize(finger, vector)
      @finger      = finger.to_i
      @direction   = vector.direction
      @event_type = vector.class::TYPE
    end
    attr_reader :finger, :direction, :event_type

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
      Config.command(self)
    end

    def shortcut
      s = Config.shortcut(self)
      return unless s
      c = "xdotool key #{s}"
      MultiLogger.warn 'shortcut property is deprecated.'
      MultiLogger.warn "Use command: #{c} instead of shortcut: #{s}"
      c
    end

    def no_command
      'echo "Command is not assigned"'
    end
  end
end
