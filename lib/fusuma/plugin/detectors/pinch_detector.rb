# frozen_string_literal: true

require_relative "./detector"

module Fusuma
  module Plugin
    module Detectors
      class PinchDetector < Detector
        SOURCES = ["gesture"].freeze
        BUFFER_TYPE = "gesture"
        GESTURE_RECORD_TYPE = "pinch"

        FINGERS = [2, 3, 4].freeze
        BASE_THERESHOLD = 1.3

        # @param buffers [Array<Buffer>]
        # @return [Events::Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          gesture_buffer = buffers.find { |b| b.type == BUFFER_TYPE }
            .select_from_last_begin
            .select_by_type(GESTURE_RECORD_TYPE)

          updating_events = gesture_buffer.updating_events
          return if updating_events.empty?

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

          prev_event, event = if status == "end"
            [
              gesture_buffer.events[-3],
              gesture_buffer.events[-2]
            ]
          else
            [
              gesture_buffer.events[-2],
              gesture_buffer.events[-1]
            ]
          end
          delta = event.record.delta
          prev_delta = prev_event.record.delta

          repeat_direction = Direction.new(target: delta.zoom, base: (prev_delta&.zoom || 1.0)).to_s
          # repeat_quantity = Quantity.new(target: delta.zoom, base: (prev_delta&.zoom || 1.0)).to_f

          repeat_index = create_repeat_index(gesture: type, finger: finger,
            direction: repeat_direction,
            status: status)
          if status == "update"
            return unless moved?(prev_event, event)

            first_zoom, avg_zoom = if updating_events.size >= 10
              [updating_events[-10].record.delta.zoom,
                gesture_buffer.class.new(
                  updating_events[-10..-1]
                ).avg_attrs(:zoom)]
            else
              [updating_events.first.record.delta.zoom,
                gesture_buffer.avg_attrs(:zoom)]
            end

            oneshot_quantity = Quantity.new(target: avg_zoom, base: first_zoom).to_f
            oneshot_direction = Direction.new(target: avg_zoom, base: first_zoom).to_s
            oneshot_index = create_oneshot_index(gesture: type, finger: finger,
              direction: oneshot_direction)
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
        def create_repeat_index(gesture:, finger:, direction:, status:)
          Config::Index.new(
            [
              Config::Index::Key.new(gesture), # 'pinch'
              Config::Index::Key.new(finger.to_i), # 2, 3, 4
              Config::Index::Key.new(direction, skippable: true), # 'in', 'out'
              Config::Index::Key.new(status) # 'begin', 'update', 'end'
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
              Config::Index::Key.new(gesture), # 'pinch'
              Config::Index::Key.new(finger.to_i, skippable: true), # 2, 3, 4
              Config::Index::Key.new(direction) # 'in', 'out'
            ]
          )
        end

        private

        def moved?(prev_event, event)
          zoom_delta = (event.record.delta.zoom - prev_event.record.delta.zoom).abs
          updating_time = (event.time - prev_event.time) * 100
          zoom_delta / updating_time > 0.01
        end

        def enough_oneshot_threshold?(index:, quantity:)
          quantity >= threshold(index: index)
        end

        def threshold(index:)
          @threshold ||= {}
          @threshold[index.cache_key] ||= begin
            keys_specific = Config::Index.new [*index.keys, "threshold"]
            keys_global = Config::Index.new ["threshold", type]
            config_value = Config.search(keys_specific) ||
              Config.search(keys_global) || 1
            BASE_THERESHOLD * config_value
          end
        end

        # direction of gesture
        class Direction
          IN = "in"
          OUT = "out"

          def initialize(target:, base:)
            @target = target.to_f
            @base = base.to_f
          end

          def to_s
            calc
          end

          def calc
            if @target > @base
              OUT
            else
              IN
            end
          end
        end

        # quantity of gesture
        class Quantity
          def initialize(target:, base:)
            @target = target.to_f
            @base = base.to_f
          end

          def to_f
            calc.to_f
          end

          def calc
            if @target > @base
              @target / @base
            else
              @base / @target
            end
          end
        end
      end
    end
  end
end
