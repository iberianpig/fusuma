# frozen_string_literal: true

require_relative "detector"

module Fusuma
  module Plugin
    module Detectors
      class SwipeDetector < Detector
        SOURCES = ["gesture"].freeze
        BUFFER_TYPE = "gesture"
        GESTURE_RECORD_TYPE = "swipe"

        FINGERS = [3, 4].freeze
        BASE_THRESHOLD = 25

        # @param buffers [Array<Buffers::Buffer>]
        # @return [Events::Event] if event is detected
        # @return [NilClass] if event is NOT detected
        #: (Array[untyped]) -> (Fusuma::Plugin::Events::Event | Array[untyped])?
        def detect(buffers)
          gesture_buffer = buffers.find { |b| b.type == BUFFER_TYPE }
            .select_from_last_begin
            .select_by_type(GESTURE_RECORD_TYPE)

          updating_events = gesture_buffer.updating_events
          return if updating_events.empty?

          updating_time = 100 * (updating_events.last.time -
                                 (updating_events[-10] || updating_events.first).time)
          oneshot_move_x = gesture_buffer.sum_last10_attrs(:move_x) / updating_time
          oneshot_move_y = gesture_buffer.sum_last10_attrs(:move_y) / updating_time

          finger = gesture_buffer.finger
          status = case gesture_buffer.events.last.record.status
          when "end"
            "end"
          when "update"
            if updating_events.length == 1
              "begin"
            else
              "update"
            end
          else
            gesture_buffer.events.last.record.status
          end

          delta = if status == "end"
            gesture_buffer.events[-2].record.delta
          else
            gesture_buffer.events.last.record.delta
          end

          repeat_direction = Direction.new(move_x: delta.move_x, move_y: delta.move_y).to_s
          repeat_quantity = Quantity.new(move_x: delta.move_x, move_y: delta.move_y).to_f

          repeat_index = create_repeat_index(gesture: type, finger: finger,
            direction: repeat_direction, status: status)

          if status == "update"
            return unless moved?(repeat_quantity)

            oneshot_direction = Direction.new(move_x: oneshot_move_x, move_y: oneshot_move_y).to_s
            oneshot_quantity = Quantity.new(move_x: oneshot_move_x, move_y: oneshot_move_y).to_f
            oneshot_index = create_oneshot_index(gesture: type, finger: finger, direction: oneshot_direction)
            if enough_oneshot_threshold?(index: oneshot_index, quantity: oneshot_quantity)
              return [
                create_event(record: Events::Records::IndexRecord.new(
                  index: oneshot_index, trigger: :oneshot, args: delta.to_h
                )),
                create_event(record: Events::Records::IndexRecord.new(
                  index: repeat_index, trigger: :repeat, args: delta.to_h
                ))
              ]
            end
          end
          create_event(record: Events::Records::IndexRecord.new(
            index: repeat_index, trigger: :repeat, args: delta.to_h
          ))
        end

        # @param [String] gesture
        # @param [Integer] finger
        # @param [String] direction
        # @param [String] status
        # @return [Config::Index]
        #: (gesture: String, finger: Integer, direction: String, status: String) -> Fusuma::Config::Index
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
        #: (gesture: String, finger: Integer, direction: String) -> Fusuma::Config::Index
        def create_oneshot_index(gesture:, finger:, direction:)
          Config::Index.new(
            [
              Config::Index::Key.new(gesture),
              Config::Index::Key.new(finger.to_i),
              Config::Index::Key.new(direction)
            ]
          )
        end

        private

        #: (Float) -> bool
        def moved?(repeat_quantity)
          repeat_quantity > 0.3
        end

        #: (index: Fusuma::Config::Index, quantity: Float) -> bool
        def enough_oneshot_threshold?(index:, quantity:)
          quantity > threshold(index: index)
        end

        #: (index: Fusuma::Config::Index) -> Integer
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

        # direction of gesture
        class Direction
          RIGHT = "right"
          LEFT = "left"
          DOWN = "down"
          UP = "up"

          #: (move_x: Integer | Float, move_y: Integer | Float) -> void
          def initialize(move_x:, move_y:)
            @move_x = move_x.to_f
            @move_y = move_y.to_f
          end

          #: () -> String
          def to_s
            calc
          end

          #: () -> String
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
          #: (move_x: Integer | Float, move_y: Integer | Float) -> void
          def initialize(move_x:, move_y:)
            @x = move_x.to_f.abs
            @y = move_y.to_f.abs
          end

          #: () -> Float
          def to_f
            calc.to_f
          end

          #: () -> Float
          def calc
            (@x > @y) ? @x.abs : @y.abs
          end
        end
      end
    end
  end
end
