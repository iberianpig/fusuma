# frozen_string_literal: true

require_relative './detector'

module Fusuma
  module Plugin
    module Detectors
      class SwipeDetector < Detector
        BUFFER_TYPE = 'gesture'
        GESTURE_RECORD_TYPE = 'swipe'

        FINGERS = [3, 4].freeze
        BASE_THERESHOLD = 10

        # @param buffers [Array<Buffers::Buffer>]
        # @return [Events::Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          gesture_buffer = buffers.find { |b| b.type == BUFFER_TYPE }
                                  .select_from_last_begin
                                  .select_by_events { |e| e.record.gesture == GESTURE_RECORD_TYPE }

          return if gesture_buffer.updating_events.empty?

          move_x = gesture_buffer.avg_attrs(:move_x)
          move_y = gesture_buffer.avg_attrs(:move_y)

          finger = gesture_buffer.finger
          direction = Direction.new(move_x: move_x.to_f, move_y: move_y.to_f).to_s
          quantity = Quantity.new(move_x: move_x.to_f, move_y: move_y.to_f).to_f

          status = if gesture_buffer.updating_events.length == 1
                     'begin'
                   else
                     gesture_buffer.events.last.record.status
                   end

          oneshot_index = create_oneshot_index(gesture: type, finger: finger, direction: direction)

          repeat_index = create_repeat_index(gesture: type, finger: finger, direction: direction,
                                             status: status)

          delta = gesture_buffer.events.last.record.direction.to_h

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
              Config::Index::Key.new(direction, skippable: true),
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
              Config::Index::Key.new(direction),
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
            keys_global = Config::Index.new ['threshold', type]
            config_value = Config.search(keys_specific) ||
                           Config.search(keys_global) || 1
            BASE_THERESHOLD * config_value
          end
        end

        # direction of gesture
        class Direction
          RIGHT = 'right'
          LEFT = 'left'
          DOWN = 'down'
          UP = 'up'

          def initialize(move_x:, move_y:)
            @move_x = move_x
            @move_y = move_y
          end

          def to_s
            calc
          end

          def calc
            if @move_x.abs > @move_y.abs
              @move_x.positive? ? RIGHT : LEFT
            elsif @move_y.positive?
              DOWN
            else
              UP
            end
          end
        end

        # quantity of gesture
        class Quantity
          def initialize(move_x:, move_y:)
            @x = move_x.abs
            @y = move_y.abs
          end

          def to_f
            calc.to_f
          end

          def calc
            @x > @y ? @x.abs : @y.abs
          end
        end
      end
    end
  end
end
