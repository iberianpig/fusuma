module Fusuma
  module Parsers
    # parse libinput and generate vector
    class LibinputGestureParser < BaseParser
      TYPE = 'gesture'.freeze
      EventBody = Struct.new(:gesture, :finger, :move_x, :move_y, :zoom, :rotate)

      def initialize(*options)
        @options = options
      end

      # @param line [String]
      # @return Event
      def parse(line)
        case line.to_s
        when /GESTURE_SWIPE|GESTURE_PINCH/
          gesture, status, time, finger, move_x, move_y, zoom, rotate = parse_libinput(line)
        when /POINTER_BUTTON.+(\d+\.\d+)s.*BTN_(LEFT|RIGHT|MIDDLE).*(pressed|released)/
          matched = Regexp.last_match
          time = matched[1]
          gesture = 'tap'
          finger = case matched[2]
                   when 'LEFT'
                     1
                   when 'RIGHT'
                     2
                   when 'MIDDLE'
                     3
                   end
          status = matched[3]

        else
          return
        end

        Event.new(time, TYPE, status,
                  EventBody.new(gesture, finger,
                                move_x.to_f,
                                move_y.to_f,
                                zoom.to_f,
                                rotate.to_f))
      end

      private

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

      class << self
        # param options [Hash]
        def generate(options:)
          libinput_gesture_options = options[:parser][:libinput_gesture]
          new(libinput_gesture_options)
        end
      end
    end
  end
end
