# frozen_string_literal: true

require_relative "detector"
require_relative "../inputs/timer_input"

module Fusuma
  module Plugin
    module Detectors
      # Detect Hold gesture
      class HoldDetector < Detector
        SOURCES = %w[gesture timer].freeze
        BUFFER_TYPE = "gesture"
        GESTURE_RECORD_TYPE = "hold"

        BASE_THRESHOLD = 0.7

        #: (*nil) -> void
        def initialize(*args)
          super
          @timer = Inputs::TimerInput.instance
        end

        # @param buffers [Array<Buffers::Buffer>]
        # @return [Events::Event] if event is detected
        # @return [Array<Events::Event>] if hold end event is detected
        # @return [NilClass] if event is NOT detected
        #: (Array[untyped]) -> Fusuma::Plugin::Events::Event?
        def detect(buffers)
          hold_buffer = find_hold_buffer(buffers)
          return if hold_buffer.empty?

          last_hold = hold_buffer.events.last

          timer_buffer = buffers.find { |b| b.type == "timer" }
          last_timer = timer_buffer.events.last

          finger = hold_buffer.finger
          holding_time = calc_holding_time(hold_events: hold_buffer.events, last_timer: last_timer)

          status = case last_hold.record.status
          when "begin"
            if holding_time.zero?
              "begin"
            else
              "timer"
            end
          when "cancelled"
            "cancelled"
          when "end"
            "end"
          else
            last_record = last_hold.record.status
            raise "Unexpected Status:#{last_record.status} in #{last_record}"
          end

          repeat_index = create_repeat_index(finger: finger, status: status)
          oneshot_index = create_oneshot_index(finger: finger)

          if status == "begin"
            @timeout = nil
            if threshold(index: oneshot_index) < @timer.interval
              @timer.wake_early(Time.now + threshold(index: oneshot_index))
            end
          elsif status == "timer"
            return if @timeout

            return unless enough?(index: oneshot_index, holding_time: holding_time)

            @timeout = holding_time
            return create_event(record: Events::Records::IndexRecord.new(
              index: oneshot_index, trigger: :oneshot
            ))
          end

          create_event(record: Events::Records::IndexRecord.new(
            index: repeat_index, trigger: :repeat
          ))
        end

        # @param [Integer] finger
        # @return [Config::Index]
        #: (finger: Integer) -> Fusuma::Config::Index
        def create_oneshot_index(finger:)
          Config::Index.new(
            [
              Config::Index::Key.new(type),
              Config::Index::Key.new(finger.to_i)
            ]
          )
        end

        # @param [Integer] finger
        # @return [Config::Index]
        #: (finger: Integer, status: String) -> Fusuma::Config::Index
        def create_repeat_index(finger:, status:)
          Config::Index.new(
            [
              Config::Index::Key.new(type),
              Config::Index::Key.new(finger.to_i),
              Config::Index::Key.new(status)
            ]
          )
        end

        private

        # @param buffers [Array<Buffers::Buffer>]
        # @return [Buffers::GestureBuffer]
        #: (Array[untyped]) -> Fusuma::Plugin::Buffers::GestureBuffer
        def find_hold_buffer(buffers)
          buffers.find { |b| b.type == BUFFER_TYPE }
            .select_from_last_begin
            .select_by_type(GESTURE_RECORD_TYPE)
        end

        #: (hold_events: Array[untyped], last_timer: nil | Fusuma::Plugin::Events::Event) -> Float
        def calc_holding_time(hold_events:, last_timer:)
          last_time = if last_timer && (hold_events.last.time < last_timer.time)
            last_timer.time
          else
            hold_events.last.time
          end
          last_time - hold_events.first.time
        end

        #: (index: Fusuma::Config::Index, holding_time: Float) -> bool
        def enough?(index:, holding_time:)
          diff = threshold(index: index) - holding_time
          if diff < 0
            true
          elsif diff < @timer.interval
            @timer.wake_early(Time.now + diff)
            false
          end
        end

        #: (index: Fusuma::Config::Index) -> Float
        def threshold(index:)
          @threshold ||= {}
          @threshold[index.cache_key] ||= begin
            keys_specific = Config::Index.new [*index.keys, "threshold"]
            keys_global = Config::Index.new ["threshold", type]
            config_value = Config.search(keys_specific) ||
              Config.search(keys_global) || 1
            BASE_THRESHOLD * config_value
          end
        end
      end
    end
  end
end
