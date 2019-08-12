# frozen_string_literal: true

require_relative './detector.rb'

module Fusuma
  module Plugin
    module Detectors
      class RotateDetector < Detector
        BUFFER_TYPE = 'gesture'
        GESTURE_RECORD_TYPE = 'pinch'

        FINGERS = [2, 3, 4].freeze
        BASE_THERESHOLD = 0.5
        BASE_INTERVAL   = 0.1

        # @param buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          buffer = buffers.find { |b| b.type == BUFFER_TYPE }
                          .select_by_events { |e| e.record.gesture == GESTURE_RECORD_TYPE }

          return if buffer.empty?

          angle = buffer.avg_attrs(:rotate)

          finger = buffer.finger
          direction = Direction.new(angle: angle).to_s
          quantity = Quantity.new(angle: angle).to_f

          vector_record = Events::Records::VectorRecord.new(gesture: type,
                                                            finger: finger,
                                                            direction: direction,
                                                            quantity: quantity)

          return unless enough?(vector_record: vector_record)

          create_event(record: vector_record)
        end

        private

        def enough?(vector_record:)
          enough_angle?(vector_record: vector_record) &&
            enough_interval?(vector_record: vector_record)
        end

        def enough_angle?(vector_record:)
          MultiLogger.info(type: type,
                           quantity: vector_record.quantity,
                           quantity_threshold: threshold(index: vector_record.index))

          vector_record.quantity > threshold(index: vector_record.index)
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
          CLOCKWISE = 'clockwise'
          COUNTERCLOCKWISE = 'counterclockwise'

          def initialize(angle:)
            @angle = angle
          end

          def to_s
            calc
          end

          def calc
            if @angle > 0
              CLOCKWISE
            else
              COUNTERCLOCKWISE
            end
          end
        end

        # quantity of vector
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
