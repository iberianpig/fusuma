module Fusuma
  # manage events and generate command
  class EventStack < Array
    ELAPSED_TIME = 0.01

    def initialize(*args)
      super(*args)
    end

    # @return [CommandExecutor, nil]
    def generate_command_executor
      return unless enough_events? 
      vector = generate_vector(detect_event_type)
      trigger = CommandExecutor.new(finger, vector)
      return unless vector.enough?(trigger)
      clear
      trigger
    end

    # @params [GestureEvent]
    def push(gesture_event)
      super(gesture_event)
      clear if event_end?
    end
    alias << push

    private

    def generate_vector(event_type)
      case event_type
      when 'swipe'
        avg_swipe
      when 'pinch'
        avg_pinch
      when 'tap'
        avg_tap
      end
    end

    def finger
      last.finger
    end

    def avg_swipe
      move_x = avg_attrs(:move_x)
      move_y = avg_attrs(:move_y)
      Swipe.new(move_x, move_y)
    end

    def avg_pinch
      diameter = avg_attrs(:zoom)
      delta_diameter = diameter - first.zoom
      Pinch.new(delta_diameter)
    end

    def avg_tap
      Tap.new()
    end  

    def sum_attrs(attr)
      send('map') do |gesture_event|
        gesture_event.send(attr.to_sym.to_s)
      end.compact.inject(:+)
    end

    def avg_attrs(attr)
      sum_attrs(attr) / length
    end

    def event_end?
      last_event_name =~ /_END$/ 
    end

    def last_event_name
      return false if last.class != GestureEvent
      last.event
    end

    def enough_events?
      length > 0
    end

    def enough_elapsed_time?
      return false if length.zero?
      (last.time - first.time) > ELAPSED_TIME
    end

    def detect_event_type
      first.event =~ /GESTURE_(.*?)_/
      Regexp.last_match(1).downcase
    end
  end
end
