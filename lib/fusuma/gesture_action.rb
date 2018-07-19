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
      def initialize_by(line, device_names)
        return if device_names.none? do |device_name|
          line.to_s =~ /^\s?#{device_name}/
        end
        return if line.to_s =~ /_BEGIN/
        return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH/
        time, action, finger, directions = gesture_action_arguments(line)
        MultiLogger.debug(time: time, action: action,
                          finger: finger, directions: directions)
        GestureAction.new(time, action, finger, directions)
      end

      private

      def gesture_action_arguments(libinput_line)
        action, time, finger, other = parse_libinput(libinput_line)
        move_x, move_y, zoom = parse_finger_directions(other)
        directions = { move: { x: move_x, y: move_y }, zoom: zoom }
        [time, action, finger, directions]
      end

      def parse_libinput(line)
        _device, action, time, other = line.strip.split(nil, 4)
        finger, other = other.split(nil, 2)
        [action, time, finger, other]
      end

      def parse_finger_directions(line)
        return [] if line.nil?
        move_x, move_y, _, _, _, zoom = line.tr('/|(|)', ' ').split
        [move_x, move_y, zoom]
      end
    end
  end
end
