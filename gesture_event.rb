module Fusuma
  # pinch or swipe or rotate event
  class GestureEvent
    def initialize(time, event, finger, directions)
      @time = time.to_f
      @event = event
      @finger = finger
      @move_x = directions[:move][:x].to_f
      @move_y = directions[:move][:y].to_f
      @zoom   = directions[:zoom].to_f
    end
    attr_reader :time, :event, :finger,
                :move_x, :move_y, :zoom

    class << self
      def initialize_by(line, device_names)
        return if device_names.none? do |device_name|
          line =~ /^\s?#{device_name}/
        end
        return if line =~ /_BEGIN/
        
        if line =~ /BTN_RIGHT/
          time, event, finger, directions = gesture_event_arguments(line)
          finger = 2
          event = event_generator(line)
          return new(time, event, finger, directions)  
        elsif line =~ /BTN_LEFT/
          time, event, finger, directions = gesture_event_arguments(line)
          finger = 1
          event = event_generator(line)
          return new(time, event, finger, directions)
        elsif line =~ /BTN_MIDDLE/
          time, event, finger, directions = gesture_event_arguments(line)
          finger = 3 
          event = event_generator(line)
          return new(time, event, finger, directions)
        end

        return unless line =~ /GESTURE_SWIPE|GESTURE_PINCH/
        time, event, finger, directions = gesture_event_arguments(line)
        MultiLogger.debug(time: time, event: event,
                          finger: finger, directions: directions)
        new(time, event, finger, directions)
      end

      private
      def event_generator(libinput_line)
        if libinput_line =~ /released/ 
          return  'GESTURE_TAP_END'  
        end
        'GESTURE_TAP_UPDATED'  
      end 
      def gesture_event_arguments(libinput_line)
        event, time, finger, other = parse_libinput(libinput_line)
        move_x, move_y, zoom = parse_finger_directions(other)
        directions = { move: { x: move_x, y: move_y }, zoom: zoom }
        [time, event, finger, directions]
      end

      def parse_libinput(line)
        _device, event, time, other = line.strip.split(nil, 4)
        finger, other = other.split(nil, 2)
        [event, time, finger, other]
      end

      def parse_finger_directions(line)
        return [] unless line
        move_x, move_y, _, _, _, zoom = line.tr('/|(|)', ' ').split
        [move_x, move_y, zoom]
      end
    end
  end
end
