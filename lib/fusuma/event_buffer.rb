require_relative 'command_executor'
require_relative 'vector'

module Fusuma
  # manage events and generate command
  class EventBuffer
    def initialize(*args)
      @events = Array.new(*args)
    end

    # @return [Vector, nil]
    def generate_vector
      return unless enough_events?

      Vectors::Generator.new(@events).generate.tap do |vector|
        return nil if vector.nil?

        @events.clear
        vector.class.touch_last_time
      end
    end

    # @param gesture_event [GestureEvent]
    def push(gesture_event)
      @events.push(gesture_event)
      reset unless updating?
    end
    alias << push

    private

    def reset
      Vectors::Generator.prev_vector = nil
      @events.clear
    end

    def updating?
      @events.last.status == 'update'
    end

    def enough_events?
      # # NOTE: Allow continuous Pinch events
      # if length > 3 && last_event_gesture =~ /GESTURE_PINCH_UPDATE/
      #   return true
      # end

      @events.length > 3
    end
  end
end
