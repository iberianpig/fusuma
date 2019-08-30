# frozen_string_literal: true

require_relative './detector.rb'

module Fusuma
  module Plugin
    module Detectors
      class PinchDetector < Detector
        BUFFER_TYPE = 'gesture'
        GESTURE_RECORD_TYPE = 'pinch'

        FINGERS = [2, 3, 4].freeze
        BASE_THERESHOLD = 0.1
        BASE_INTERVAL   = 0.1

        # @param buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          buffer = buffers.find { |b| b.type == BUFFER_TYPE }
                          .select_by_events { |e| e.record.gesture == GESTURE_RECORD_TYPE }

          return if buffer.empty?

          finger = buffer.finger

          avg_zoom = buffer.avg_attrs(:zoom)
          first_zoom = buffer.events.first.record.direction.zoom
          diameter = avg_zoom / first_zoom

          direction = Direction.new(diameter: diameter).to_s
          quantity = Quantity.new(diameter: diameter).to_f

          index = create_index(gesture: type,
                               finger: finger,
                               direction: direction)

          return unless enough?(index: index, quantity: quantity)

          create_event(record: Events::Records::IndexRecord.new(index: index))
        end

        # @param [String] gesture
        # @param [Integer] finger
        # @param [String] direction
        # @return [Config::Index]
        def create_index(gesture:, finger:, direction:)
          Config::Index.new(
            [
              Config::Index::Key.new(gesture),
              Config::Index::Key.new(finger.to_i, skippable: true),
              Config::Index::Key.new(direction)
            ]
          )
        end

        private

        def enough?(index:, quantity:)
          enough_interval?(index: index) && enough_diameter?(index: index, quantity: quantity)
        end

        def enough_diameter?(index:, quantity:)
          MultiLogger.info(type: type, quantity: quantity,
                           quantity_threshold: threshold(index: index))
          quantity >= threshold(index: index)
        end

        def enough_interval?(index:)
          return true if first_time?
          return true if (Time.now - @last_time) > interval_time(index: index)

          false
        end

        def first_time?
          !@last_time
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

        def interval_time(index:)
          @interval_time ||= {}
          @interval_time[index.cache_key] ||= begin
                               keys_specific = Config::Index.new [*index.keys, 'interval']
                               keys_global = Config::Index.new ['interval', type]
                               config_value = Config.search(keys_specific) ||
                                              Config.search(keys_global) || 1
                               BASE_INTERVAL * config_value
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
          def initialize(diameter:)
            @diameter = diameter
          end

          def to_f
            calc.to_f
          end

          def calc
            (1.0 - @diameter).abs
          end
        end
      end
    end
  end
end
