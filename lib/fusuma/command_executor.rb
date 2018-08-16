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
      return if command.nil?
      `#{command}`
      MultiLogger.info("Execute: #{command}")
    end

    private

    def command
      Config.command(self).tap { |c| return c if c }
      Config.shortcut(self).tap { |s| return "xdotool key #{s}" if s }
    end
  end
end
