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
      `#{command_or_shortcut}`
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
      Config.shortcut(self).tap { |s| return "xdotool key #{s}" if s }
    end

    def no_command
      'echo "Command is not assigned"'
    end
  end
end
