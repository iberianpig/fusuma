# frozen_string_literal: true

require_relative './buffer'

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class GestureBuffer < Buffer
        DEFAULT_SOURCE = 'libinput_gesture_parser'
        DEFAULT_SECONDS_TO_KEEP = 100

        def config_param_types
          {
            'source': [String],
            'seconds_to_keep': [Float, Integer]
          }
        end

        # @param event [Event]
        # @return [Buffer, FalseClass]
        def buffer(event)
          # TODO: buffering events into buffer plugins
          # - gesture event buffer
          # - window event buffer
          # - other event buffer
          return if event&.tag != source

          @events.push(event)
          self
        end

        def clear_expired(current_time: Time.now)
          clear if ended?

          @seconds_to_keep ||= (config_params(:seconds_to_keep) || DEFAULT_SECONDS_TO_KEEP)
          @events.each do |e|
            break if current_time - e.time < @seconds_to_keep

            MultiLogger.debug("#{self.class.name}##{__method__}")

            @events.delete(e)
          end
        end

        def ended?
          return false if empty?

          @events.last.record.status == 'end'
        end

        # @param attr [Symbol]
        # @return [Float]
        def sum_attrs(attr)
          updating_events.map do |gesture_event|
            gesture_event.record.direction[attr].to_f
          end.inject(:+)
        end

        def updating_events
          @events.select { |e| e.record.status == 'update' }
        end

        # @param attr [Symbol]
        # @return [Float]
        def avg_attrs(attr)
          sum_attrs(attr).to_f / updating_events.length
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

        def select_by_events(&block)
          return enum_for(:select_by_events) unless block_given?

          events = @events.select(&block)
          self.class.new events
        end

        def select_from_last_begin
          return self if empty?

          index_from_last = @events.reverse.find_index { |e| e.record.status == 'begin' }
          return GestureBuffer.new([]) if index_from_last.nil?

          index_last_begin = events.length - index_from_last - 1
          GestureBuffer.new(@events[index_last_begin..-1])
        end
      end
    end
  end
end
