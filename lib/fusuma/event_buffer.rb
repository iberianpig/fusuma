require_relative 'command_executor'
require_relative 'plugin/vector'

module Fusuma
  # manage events and generate command
  class EventBuffer
    def initialize(*args)
      @events = Array.new(*args)
    end
    attr_reader :events

    # @return [Vector, nil]
    def generate_vector
      return unless enough_events?

      Plugin::Vectors::Generator.new(event_buffer: self).generate.tap do |vector|
        return nil if vector.nil?

        @events.clear
        vector.class.touch_last_time
      end
    end

    # @param event [Event]
    def push(event)
      @events.push(event)
      reset unless updating?
    end
    alias << push

    # @param attr [Symbol]
    # @retrun [Float]
    def sum_attrs(attr)
      @events.map do |gesture_event|
        gesture_event.record[attr]
      end.compact.inject(:+)
    end

    # @param attr [Symbol]
    # @retrun [Float]
    def avg_attrs(attr)
      sum_attrs(attr) / @events.length
    end

    # return [Integer]
    def finger
      @events.last.record.finger
    end

    # @example
    #  event_buffer.gesture
    #  => 'swipe'
    # @return [String]
    def gesture
      @events.last.record.gesture
    end

    private

    def reset
      Plugin::Vectors::Generator.prev_vector = nil
      @events.clear
    end

    def updating?
      return true unless @events.last.record.status =~ /begin|end/
    end

    def enough_events?
      !@events.empty?
    end
  end
end
