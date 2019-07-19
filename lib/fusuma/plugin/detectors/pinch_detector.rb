# frozen_string_literal: true

module Fusuma
  module Plugin
    module Detectors
      # vector data
      class PinchDetector < Detector
        GESTURE = 'pinch'

        BASE_THERESHOLD = 0.1
        BASE_INTERVAL   = 0.1

        # def initialize(finger, diameter = 0)
        #   @finger = finger.to_i
        #   @direction = Direction.new(diameter: diameter.to_f).to_s
        #   @quantity = Quantity.new(diameter: diameter.to_f).to_f
        # end
        #
        # attr_reader :finger, :direction, :quantity

        def enough?
          enough_diameter? && enough_interval?
        end

        private

        def enough_diameter?
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
            pinch_events = event_buffer.select { |event| event.record.gesture == GESTURE }
            return if pinch_events.empty?

            return if Generator.prev_vector && Generator.prev_vector != self

            Detectors::PinchDetector.new(pinch_events.finger,
                                         calc_diameter(pinch_events)).tap do |v|
              return nil unless v.enough?

              Generator.prev_vector = self
            end
          end

          private

          def calc_diameter(event_buffer)
            avg_zoom = event_buffer.avg_attrs(:zoom)
            first_zoom = event_buffer.events.first.record.direction.zoom
            avg_zoom / first_zoom
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
            @diameter.to_f
          end
        end
      end
    end
  end
end
