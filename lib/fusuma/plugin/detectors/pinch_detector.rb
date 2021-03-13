# frozen_string_literal: true

require_relative './detector'

module Fusuma
  module Plugin
    module Detectors
      class PinchDetector < Detector
        SOURCES = ['gesture']
        BUFFER_TYPE = 'gesture'
        GESTURE_RECORD_TYPE = 'pinch'

        FINGERS = [2, 3, 4].freeze
        BASE_THERESHOLD = 1.3

        # @param buffers [Array<Buffer>]
        # @return [Events::Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          gesture_buffer = buffers.find { |b| b.type == BUFFER_TYPE }
                                  .select_from_last_begin
                                  .select_by_events { |e| e.record.gesture == GESTURE_RECORD_TYPE }

          updating_events = gesture_buffer.updating_events
          return if updating_events.empty?

          finger = gesture_buffer.finger

          status = if updating_events.length == 1
                     'begin'
                   else
                     gesture_buffer.events.last.record.status
                   end

          delta = if status == 'end'
                    gesture_buffer.events[-2].record.delta
                  else
                    gesture_buffer.events.last.record.delta
                  end

          direction = Direction.new(diameter: delta.zoom.to_f).to_s

          repeat_index = create_repeat_index(gesture: type, finger: finger,
                                             direction: direction,
                                             status: status)

          if status == 'update'
            avg_zoom = gesture_buffer.avg_attrs(:zoom)
            first_zoom = updating_events.first.record.delta.zoom
            quantity = Quantity.new(target: avg_zoom, base: first_zoom).to_f
            # puts ({quantity: quantity, avg_zoom: avg_zoom, first_zoom: first_zoom})
            oneshot_index = create_oneshot_index(gesture: type, finger: finger,
                                                 direction: direction)
            if enough_oneshot_threshold?(index: oneshot_index, quantity: quantity)
              return [
                create_event(
                  record: Events::Records::IndexRecord.new(
                    index: oneshot_index, trigger: :oneshot, args: delta.to_h
                  )),
                create_event(
                  record: Events::Records::IndexRecord.new(
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
              Config::Index::Key.new(direction)
            ]
          )
        end

        private

        def enough_oneshot_threshold?(index:, quantity:)
          quantity >= threshold(index: index)
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
          IN = 'in'
          OUT = 'out'

          def initialize(diameter:)
            @diameter = diameter
          end

          def to_s
            calc
          end

          def calc
            if @diameter > 1
              IN
            else
              OUT
            end
          end
        end

        # quantity of gesture
        class Quantity
          def initialize(target:, base:)
            @target = target
            @base = base
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
