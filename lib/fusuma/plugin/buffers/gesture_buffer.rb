# frozen_string_literal: true

require_relative "./buffer"

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class GestureBuffer < Buffer
        DEFAULT_SOURCE = "libinput_gesture_parser"
        DEFAULT_SECONDS_TO_KEEP = 100

        def initialize(*args)
          super(*args)
          @mem_last_begin = nil # last index at which we saw a begin
          @mem_checked = 0 # length of @events when we saw it
        end

        def clear
          super.clear
          @mem_last_begin = nil
          @mem_checked = 0
        end

        def config_param_types
          {
            source: [String],
            seconds_to_keep: [Float, Integer]
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
            @mem_last_begin = nil
            @mem_checked = 0
          end
        end

        def ended?
          return false if empty?

          case @events.last.record.status
          when "end", "cancelled"
            true
          else
            false
          end
        end

        # @param attr [Symbol]
        # @return [Float]
        def sum_attrs(attr)
          updating_events.map do |gesture_event|
            gesture_event.record.delta[attr].to_f
          end.inject(:+)
        end

        def updating_events
          @events.select { |e| e.record.status == "update" }
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
          return enum_for(:select_by_events) unless block

          events = @events.select(&block)
          self.class.new events
        end

        def select_from_last_begin
          return self if empty?

          @mem_last_begin = (@events.length - 1).downto(@mem_checked).find do |i|
            @events[i].record.status == "begin"
          end || @mem_last_begin
          @mem_checked = @events.length

          return self if @mem_last_begin == 0
          return GestureBuffer.new([]) if @mem_last_begin.nil?

          GestureBuffer.new(@events[@mem_last_begin..-1])
        end
      end
    end
  end
end
