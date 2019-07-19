# frozen_string_literal: true

module Fusuma
  module Plugin
    module Detectors
      # vector data
      class RotateDetector < Detector
        GESTURE = 'pinch'

        BASE_THERESHOLD = 0.5
        BASE_INTERVAL   = 0.1

        # def initialize(finger, angle = 0)
        #   @finger = finger.to_i
        #   @direction = Direction.new(angle: angle.to_f).to_s
        #   @quantity = Quantity.new(angle: angle.to_f).to_f
        # end
        # attr_reader :finger, :direction, :quantity

        def enough?
          enough_angle? && enough_interval?
        end

        private

        def enough_angle?
          quantity > threshold
        end

        def enough_interval?
          return true if first_time?
          return true if (Time.now - self.class.last_time) > interval_time

          false
        end

        def first_time?
          !self.class.last_time
        end

        def threshold
          @threshold ||= begin
                           keys_specific = Config::Index.new [*index.keys, 'threshold']
                           keys_global   = Config::Index.new ['threshold', self.class.type]
                           config_value  = Config.search(keys_specific) ||
                                           Config.search(keys_global) || 1
                           BASE_THERESHOLD * config_value
                         end
        end

        def interval_time
          @interval_time ||= begin
                               keys_specific = Config::Index.new [*index.keys, 'interval']
                               keys_global = Config::Index.new ['interval', self.class.type]
                               config_value = Config.search(keys_specific) ||
                                              Config.search(keys_global) || 1
                               BASE_INTERVAL * config_value
                             end
        end

        class << self
          attr_reader :last_time

          def generate(event_buffer:)
            rotate_events = event_buffer.select { |event| event.record.gesture == GESTURE }
            return if rotate_events.empty?

            return if Generator.prev_vector && Generator.prev_vector != self

            angle = rotate_events.avg_attrs(:rotate)
            new(rotate_events.finger, angle).tap do |v|
              return nil unless v.enough?

              Generator.prev_vector = self
            end
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
