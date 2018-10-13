module Fusuma
  # Event
  class GestureEvent
    Direction = Struct.new(:move_x, :move_y, :zoom, :rotate)

    def initialize(time, event, finger, direction)
      @time   = time.to_f
      @event  = event
      @finger = finger
      @direction = direction
    end
    attr_reader :time, :event, :finger, :direction

    class << self
      # @return [GestureEvent, nil]
      def initialize_by(line, device_names)
        return if device_names.none? do |device_name|
          line =~ /^\s?#{device_name}/
        end
        return if line.to_s =~ /_BEGIN/
        return unless line.to_s =~ /GESTURE_SWIPE|GESTURE_PINCH/

        time, event, finger, direction = pluck_out(line)
        MultiLogger.debug(time: time, event: event,
                          finger: finger, direction: direction)
        new(time, event, finger, direction)
      end

      private

      # @return direction
      def pluck_out(libinput_line)
        event, time, finger, move_x, move_y, zoom, rotate =
          parse_libinput(libinput_line)
        direction = Direction.new(move_x.to_f, move_y.to_f,
                                  zoom.to_f, rotate.to_f)
        [time, event, finger, direction]
      end

      def parse_libinput(line)
        _device, event, time, other = line.strip.split(nil, 4)
        finger, other = other.split(nil, 2)
        move_x, move_y, zoom, rotate = parse_finger_direction(other)
        [event, time, finger, move_x, move_y, zoom, rotate]
      end

      def parse_finger_direction(line)
        return [] if line.nil?

        move_x, move_y, _, _, _, zoom, _, rotate = line.tr('/|(|)', ' ').split
        [move_x, move_y, zoom, rotate]
      end
    end
  end
end
