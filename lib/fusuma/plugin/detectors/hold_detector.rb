# frozen_string_literal: true

require_relative './detector'

module Fusuma
  module Plugin
    module Detectors
      class HoldDetector < Detector
        SOURCES = ['gesture'].freeze
        BUFFER_TYPE = 'gesture'
        GESTURE_RECORD_TYPE = 'hold'

        FINGERS = [3, 4].freeze
        BASE_THERESHOLD = 25

        # @param buffers [Array<Buffers::Buffer>]
        # @return [Events::Event] if event is detected
        # @return [Array<Events::Event>] if hold end event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          gesture_buffer = find_gesture_buffer(buffers)
          return if gesture_buffer.empty?

          finger = gesture_buffer.finger
          status = case gesture_buffer.events.last.record.status
                   when 'begin'
                     'begin'
                   when 'cancelled'
                     'cancelled'
                   when 'end'
                     'end'
                   else
                     last_record = gesture_buffer.events.last.record.status
                     raise "Unexpected Status:#{last_record.status} in #{last_record}"
                   end


          if status != 'end'
            return create_event(record: Events::Records::IndexRecord.new(
              index: create_repeat_index(finger: finger, status: status), trigger: :repeat
            ))
          end


          [
            create_event(record: Events::Records::IndexRecord.new(
              index: create_oneshot_index(finger: finger), trigger: :oneshot
            )),
            create_event(record: Events::Records::IndexRecord.new(
              index: create_repeat_index(finger: finger, status: status), trigger: :repeat
            ))
          ]
        end

        # @param [Integer] finger
        # @return [Config::Index]
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
        def find_gesture_buffer(buffers)
          buffers.find { |b| b.type == BUFFER_TYPE }
                 .select_from_last_begin
                 .select_by_events { |e| e.record.gesture == GESTURE_RECORD_TYPE }
        end
      end
    end
  end
end
