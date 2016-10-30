module Fusuma
  # pinch or swipe action
  class GestureAction
    def initialize(time, action, finger, directions)
      @time   = time
      @action = action
      @finger = finger
      @move_x = directions[:move][:x].to_f
      @move_y = directions[:move][:y].to_f
      @pinch  = directions[:pinch].to_f
    end
    attr_reader :time, :action, :finger,
                :move_x, :move_y, :pinch

    class << self
      def initialize_by_libinput(line, device_name)
        return unless line.to_s =~ /^#{device_name}/
        return if line.to_s =~ /_BEGIN/
        return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH/
        time, action, finger, directions = gesture_action_arguments(line)
        logger.debug(line)
        logger.debug(directions)
        GestureAction.new(time, action, finger, directions)
      end

      private

      def gesture_action_arguments(libinput_line)
        action, time, finger_directions = parse_libinput(libinput_line)
        finger, move_x, move_y, pinch = parse_finger_directions(finger_directions)
        directions = { move: { x: move_x, y: move_y }, pinch: pinch }
        [time, action, finger, directions]
      end

      def parse_libinput(line)
        _device, action_time, finger_directions = line.split("\t").map(&:strip)
        action, time = action_time.split
        [action, time, finger_directions]
      end

      def parse_finger_directions(finger_directions_line)
        finger_num, move_x, move_y, _, _, _, pinch =
          finger_directions_line.tr('/', ' ').split
        [finger_num, move_x, move_y, pinch]
      end

      def logger
        @logger ||= begin
                      log = Logger.new(STDOUT)
                      log.level = Logger::WARN
                      log
                    end
      end
    end
  end
end
