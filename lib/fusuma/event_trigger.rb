module Fusuma
  # manage actions
  class EventTrigger
    def initialize(finger, direction, action_type)
      @finger      = finger.to_i
      @direction   = direction
      @action_type = action_type
    end
    attr_reader :finger, :direction, :action_type

    def exec_command
      return if command.nil?
      `#{command}`
      MultiLogger.info("trigger event: #{command}")
    end

    private

    def command
      Config.command(self).tap { |c| return c if c }
      Config.shortcut(self).tap { |s| return "xdotool key #{s}" if s }
    end
  end
end
