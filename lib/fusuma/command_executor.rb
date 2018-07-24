module Fusuma
  # Execute Command
  class CommandExecutor
    def initialize(finger, direction, event_type)
      @finger      = finger.to_i
      @direction   = direction
      @event_type = event_type
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
