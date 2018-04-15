module Fusuma
  # manage actions
  class EventTrigger
    def initialize(finger, direction, action_type)
      @finger      = finger.to_i
      @direction   = direction
      @action_type = action_type
    end
    attr_reader :finger, :direction, :action_type

    def send_command
      MultiLogger.info("trigger event: #{command}")
      exec_command(command)
    end

    private

    def exec_command(command)
      `#{command}` unless command.nil?
    end

    def command
      Config.command(self) || "xdotool key #{Config.shortcut(self)}"
    end
  end
end
