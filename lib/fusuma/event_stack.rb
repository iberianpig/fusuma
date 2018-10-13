require_relative 'command_executor'
require_relative 'swipe.rb'
require_relative 'pinch.rb'
require_relative 'rotate.rb'

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
      return if vector.nil?
      clear
      vector.class.touch_last_time
      CommandExecutor.new(vector)
    end

    # @params [GestureEvent]
    def push(gesture_event)
      super(gesture_event)
      clear if event_end?
    end
    alias << push

    private

    # @return [vector]
    def generate_vector(event_type)
      case event_type
      when 'swipe'
        generate_swipe
      when 'pinch'
        # NOTE: put Rotate ahead of Pinch
        generate_rotate || generate_pinch
      end
    end

    def finger
      last.finger
    end

    def generate_swipe
      move_x = avg_attrs(:move_x)
      move_y = avg_attrs(:move_y)
      Swipe.new(finger, move_x, move_y).tap do |v|
        return nil unless v.enough?
      end
    end

    def generate_pinch
      diameter = avg_attrs(:zoom) - first.direction.zoom
      Pinch.new(finger, diameter).tap do |v|
        return nil unless v.enough?
      end
    end

    def generate_rotate
      angle = avg_attrs(:rotate)
      Rotate.new(finger, angle).tap do |v|
        return nil unless v.enough?
      end
    end

    def sum_attrs(attr)
      map do |gesture_event|
        gesture_event.direction[attr]
      end.compact.inject(:+)
    end

    def avg_attrs(attr)
      sum_attrs(attr) / length
    end

    def event_end?
      last_event_name =~ /_END$/
    end

    def last_event_name
      return if last.class != GestureEvent

      last.event
    end

    def enough_events?
      return true if last_event_name =~ /GESTURE_PINCH_UPDATE/
      length > 5 && enough_elapsed_time?
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
