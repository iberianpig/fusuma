module Fusuma
  # pinch or swipe action
  class GestureAction
    def initialize(time, action, finger, directions)
      @time   = time.to_f
      @action = action
      @finger = finger
      @move_x = directions[:move][:x].to_f
      @move_y = directions[:move][:y].to_f
      @zoom   = directions[:zoom].to_f
    end
    attr_reader :time, :action, :finger,
                :move_x, :move_y, :zoom

    class << self
      def initialize_by(line, device_name)
        return unless line.to_s =~ /^\s?#{device_name}/
        return if line.to_s =~ /_BEGIN/
        return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH/
        time, action, finger, directions = gesture_action_arguments(line)
        MultiLogger.debug(time: time, action: action,
                          finger: finger, directions: directions)
        GestureAction.new(time, action, finger, directions)
      end

      private

      def gesture_action_arguments(libinput_line)
        action, time, finger_directions = parse_libinput(libinput_line)
        finger, move_x, move_y, zoom =
          parse_finger_directions(finger_directions)
        directions = { move: { x: move_x, y: move_y }, zoom: zoom }
        [time, action, finger, directions]
      end

      def parse_libinput(line)
        _device, action_time, finger_directions = line.split("\t").map(&:strip)
        action, time = action_time.split
        [action, time, finger_directions]
      end

      def parse_finger_directions(finger_directions_line)
        finger_num, move_x, move_y, _, _, _, zoom =
          finger_directions_line.tr('/', ' ').split
        [finger_num, move_x, move_y, zoom]
      end
    end
  end
end
