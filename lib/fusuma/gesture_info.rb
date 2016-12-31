module Fusuma
  # manage actions
  class GestureInfo
    def initialize(finger, direction, action_type)
      @finger      = finger.to_i
      @direction   = direction
      @action_type = action_type
    end
    attr_reader :finger, :direction, :action_type

    def trigger_keyevent
      exec_xdotool(shortcut)
    end

    private

    def exec_xdotool(keys)
      `xdotool key #{keys}` unless keys.nil?
    end

    def shortcut
      @config ||= Config.instance
      @config.shortcut(self)
    end
  end
end
