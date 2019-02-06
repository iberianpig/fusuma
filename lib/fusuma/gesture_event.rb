module Fusuma
  # Event
  class GestureEvent
    Direction = Struct.new(:move_x, :move_y, :zoom, :rotate)

    def initialize(time, gesture, status, finger, direction)
      @time = time.to_f
      @gesture = gesture
      @status = status
      @finger = finger
      @direction = direction
    end
    attr_reader :time, :gesture, :status, :finger, :direction

    class << self
      # @return [GestureEvent, nil]
      def initialize_by(line, device_names)
        return if device_names.none? do |device_name|
          line =~ /^\s?#{device_name}/
        end
        return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH/

        time, gesture, status, finger, direction = pluck_out(line)
        MultiLogger.debug(time: time, gesture: gesture,
                          status: status, finger: finger)
        new(time, gesture, status, finger, direction)
      end

      private

      # @return direction
      def pluck_out(line)
        gesture, status, time, finger, move_x, move_y, zoom, rotate =
          parse_libinput(line)
        direction = Direction.new(move_x.to_f, move_y.to_f,
                                  zoom.to_f, rotate.to_f)
        [time, gesture, status, finger, direction]
      end

      def parse_libinput(line)
        _device, event_name, time, other = line.strip.split(nil, 4)
        finger, other = other.split(nil, 2)
        move_x, move_y, zoom, rotate = parse_finger_direction(other)
        [*detect_gesture(event_name), time, finger,
         move_x, move_y, zoom, rotate]
      end

      def detect_gesture(event_name)
        event_name =~ /GESTURE_(SWIPE|PINCH)_(BEGIN|UPDATE|END)/
        [Regexp.last_match(1).downcase, Regexp.last_match(2).downcase]
      end

      def parse_finger_direction(line)
        return [] if line.nil?

        move_x, move_y, _, _, _, zoom, _, rotate = line.tr('/|(|)', ' ').split
        [move_x, move_y, zoom, rotate]
      end
    end
  end
end
