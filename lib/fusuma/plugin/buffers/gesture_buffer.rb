# frozen_string_literal: true

require_relative "./buffer"

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class GestureBuffer < Buffer
        CacheEntry = Struct.new(:checked, :value)
        DEFAULT_SOURCE = "libinput_gesture_parser"
        DEFAULT_SECONDS_TO_KEEP = 100

        def initialize(*args)
          super(*args)
          @cache = {}
          @cache_select_by = {}
          @cache_sum10 = {}
        end

        def clear
          super.clear
          @cache = {}
          @cache_select_by = {}
          @cache_sum10 = {}
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
            @cache = {}
            @cache_select_by = {}
            @cache_sum10 = {}
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
          end.reduce(:+)
        end

        # @param attr [Symbol]
        # @return [Float]
        def sum_last10_attrs(attr) # sums last 10 values of attr (or all if length < 10)
          cache_entry = (@cache_sum10[attr] ||= CacheEntry.new(0, 0))
          upd_ev = updating_events
          if upd_ev.length > cache_entry.checked + 1
            cache_entry.value = upd_ev.last(10).map do |gesture_event|
              gesture_event.record.delta[attr].to_f
            end.reduce(:+)
          elsif upd_ev.length > cache_entry.checked
            cache_entry.value = cache_entry.value + upd_ev[-1].record.delta[attr].to_f - \
              ((upd_ev.length > 10) ? upd_ev[-11].record.delta[attr].to_f : 0)
          else
            return cache_entry.value
          end
          cache_entry.checked = upd_ev.length
          cache_entry.value
        end

        def updating_events
          cache_entry = (@cache[:updating_events] ||= CacheEntry.new(0, []))
          cache_entry.checked.upto(@events.length - 1).each do |i|
            (cache_entry.value << @events[i]) if @events[i].record.status == "update"
          end
          cache_entry.checked = @events.length
          cache_entry.value
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

        def select_by_type(type)
          cache_entry = (@cache_select_by[type] ||= CacheEntry.new(0, self.class.new([])))
          cache_entry.checked.upto(@events.length - 1).each do |i|
            (cache_entry.value.events << @events[i]) if @events[i].record.gesture == type
          end
          cache_entry.checked = @events.length
          cache_entry.value
        end

        def select_from_last_begin
          return self if empty?
          cache_entry = (@cache[:last_begin] ||= CacheEntry.new(0, nil))

          cache_entry.value = (@events.length - 1).downto(cache_entry.checked).find do |i|
            @events[i].record.status == "begin"
          end || cache_entry.value
          cache_entry.checked = @events.length

          return self if cache_entry.value == 0
          return GestureBuffer.new([]) if cache_entry.value.nil?

          GestureBuffer.new(@events[cache_entry.value..-1])
        end
      end
    end
  end
end
