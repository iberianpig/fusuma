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

          buffer = buffer.select_by_events { |event| event.record.gesture == GESTURE_RECORD_TYPE }

          return if buffer.empty?

          finger = buffer.finger

          avg_zoom = buffer.avg_attrs(:zoom)
          first_zoom = buffer.events.first.record.direction.zoom
          diameter = avg_zoom / first_zoom

          direction = Direction.new(diameter: diameter).to_s
          quantity = Quantity.new(diameter: diameter).to_f

          vector_record = Events::Records::VectorRecord.new(gesture: type,
                                                            finger: finger,
                                                            direction: direction,
                                                            quantity: quantity)

          return unless enough?(vector_record: vector_record)

          create_event(record: vector_record)
        end

        private

        def enough?(vector_record:)
          enough_diameter?(vector_record: vector_record) &&
            enough_interval?(vector_record: vector_record)
        end

        def enough_diameter?(vector_record:)
          MultiLogger.info(type: type, quantity: vector_record.quantity,
                           quantity_threshold: threshold(index: vector_record.index))
          vector_record.quantity >= threshold(index: vector_record.index)
        end

        def enough_interval?(vector_record:)
          return true if first_time?
          return true if (Time.now - @last_time) > interval_time(index: vector_record.index)

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

        # direction of vector
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

        # quantity of vector
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
