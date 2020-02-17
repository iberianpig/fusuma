# frozen_string_literal: true

require_relative './buffer.rb'

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class GestureBuffer < Buffer
        DEFAULT_SOURCE = 'libinput_gesture_parser'
        DEFAULT_SECONDS_TO_KEEP = 0.1

        def config_param_types
          {
            'source': [String],
            'seconds_to_keep': [Float, Integer]
          }
        end

        # @param event [Event]
        def buffer(event)
          # TODO: buffering events into buffer plugins
          # - gesture event buffer
          # - window event buffer
          # - other event buffer
          return if event&.tag != source

          delete_old_events

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

        # Delete old events pushed before 0.1sec
        def delete_old_events
          @seconds_to_keep ||= (config_params(:seconds_to_keep) || DEFAULT_SECONDS_TO_KEEP)
          @events.each do |e|
            break if Time.now - e.time < @seconds_to_keep

            @events.delete(e)
          end
        end

        def updating?
          return true unless @events.last.record.status =~ /begin|end/
        end
      end
    end
  end
end
