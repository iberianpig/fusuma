# frozen_string_literal: true

require_relative './buffer.rb'

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class GestureBuffer < Buffer
        DEFAULT_SOURCE = 'libinput_gesture_parser'

        # @param event [Event]
        def buffer(event)
          # TODO: buffering events into buffer plugins
          # - gesture event buffer
          # - window event buffer
          # - other event buffer
          return if event&.tag != source
          return if event.record.type != :gesture

          @events.push(event)
          clear unless updating?
        end

        # @param attr [Symbol]
        # @return [Float]
        def sum_attrs(attr)
          @events.map { |gesture_event| gesture_event.record.direction[attr].to_f }
                 .inject(:+)
        end

        # @param attr [Symbol]
        # @return [Float]
        def avg_attrs(attr)
          sum_attrs(attr).to_f / @events.length
        end

        # return [Integer]
        def finger
          @events.last.record.finger.to_i
        end

        # @example
        #  event_buffer.gesture
        #  => 'swipe'
        # @return [String]
        def gesture
          @events.last.record.gesture
        end

        def empty?
          @events.empty?
        end

        def select_by_events
          return enum_for(:select) unless block_given?

          events = @events.select { |event| yield event }
          self.class.new events
        end

        private

        def updating?
          return true unless @events.last.record.status =~ /begin|end/
        end
      end
    end
  end
end
