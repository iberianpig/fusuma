# frozen_string_literal: true

require_relative './detector'

module Fusuma
  module Plugin
    module Detectors
      class RotateDetector < Detector
        SOURCES = ['gesture']
        BUFFER_TYPE = 'gesture'
        GESTURE_RECORD_TYPE = 'pinch'

        FINGERS = [2, 3, 4].freeze
        BASE_THERESHOLD = 0.5

        # @param buffers [Array<Buffer>]
        # @return [Events::Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          gesture_buffer = buffers.find { |b| b.type == BUFFER_TYPE }
                                  .select_from_last_begin
                                  .select_by_events { |e| e.record.gesture == GESTURE_RECORD_TYPE }

          events = gesture_buffer.updating_events
          return if events.empty?

          finger = gesture_buffer.finger

          angle = gesture_buffer.avg_attrs(:rotate)
          direction = Direction.new(angle: angle).to_s
          quantity = Quantity.new(angle: angle).to_f

          status = if gesture_buffer.updating_events.length == 1
                     'begin'
                   else
                     gesture_buffer.events.last.record.status
                   end

          oneshot_index = create_oneshot_index(gesture: type, finger: finger, direction: direction)

          repeat_index = create_repeat_index(gesture: type, finger: finger, direction: direction,
                                             status: status)

          delta = gesture_buffer.events.last.record.delta.to_h

          if status == 'update'
            if enough_oneshot_threshold?(index: oneshot_index, quantity: quantity)
              create_event(record: Events::Records::IndexRecord.new(
                index: oneshot_index, trigger: :oneshot, args: delta
              ))
            else
              create_event(record: Events::Records::IndexRecord.new(
                index: repeat_index, trigger: :repeat, args: delta
              ))
            end
          else
            create_event(record: Events::Records::IndexRecord.new(
              index: repeat_index, trigger: :repeat, args: delta
            ))
          end
        end

        # @param [String] gesture
        # @param [Integer] finger
        # @param [String] direction
        # @param [String] status
        # @return [Config::Index]
        def create_repeat_index(gesture:, finger:, direction:, status:)
          Config::Index.new(
            [
              Config::Index::Key.new(gesture),
              Config::Index::Key.new(finger.to_i),
              Config::Index::Key.new(direction),
              Config::Index::Key.new(status)
            ]
          )
        end

        # @param [String] gesture
        # @param [Integer] finger
        # @param [String] direction
        # @return [Config::Index]
        def create_oneshot_index(gesture:, finger:, direction:)
          Config::Index.new(
            [
              Config::Index::Key.new(gesture),
              Config::Index::Key.new(finger.to_i, skippable: true),
              Config::Index::Key.new(direction)
            ]
          )
        end

        private

        def enough_oneshot_threshold?(index:, quantity:)
          quantity > threshold(index: index)
        end

        def threshold(index:)
          @threshold ||= {}
          @threshold[index.cache_key] ||= begin
            keys_specific = Config::Index.new [*index.keys, 'threshold']
            keys_global   = Config::Index.new ['threshold', type]
            config_value  = Config.search(keys_specific) ||
                            Config.search(keys_global) || 1
            BASE_THERESHOLD * config_value
          end
        end

        # direction of gesture
        class Direction
          CLOCKWISE = 'clockwise'
          COUNTERCLOCKWISE = 'counterclockwise'

          def initialize(angle:)
            @angle = angle
          end

          def to_s
            calc
          end

          def calc
            if @angle.positive?
              CLOCKWISE
            else
              COUNTERCLOCKWISE
            end
          end
        end

        # quantity of gesture
        class Quantity
          def initialize(angle:)
            @angle = angle.abs
          end

          def to_f
            @angle.to_f
          end
        end
      end
    end
  end
end
