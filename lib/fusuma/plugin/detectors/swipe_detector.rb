# frozen_string_literal: true

module Fusuma
  module Plugin
    module Detectors
      # vector data
      class SwipeDetector < Detector
        GESTURE = 'swipe'
        FINGERS = [3, 4].freeze

        BASE_THERESHOLD = 10
        BASE_INTERVAL   = 0.5

        def detect(buffers:)
          buffers.do_something
          event
        end

        # def initialize(finger, move_x = 0, move_y = 0)
        #   @finger = finger.to_i
        #   @direction = Direction.new(move_x: move_x.to_f, move_y: move_y.to_f).to_s
        #   @quantity = Quantity.new(move_x: move_x.to_f, move_y: move_y.to_f).to_f
        # end
        # attr_reader :finger, :direction, :quantity

        def enough?
          MultiLogger.debug(self)
          enough_distance? && enough_interval?
        end

        private

        def enough_distance?
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
                           keys_global = Config::Index.new ['threshold', self.class.type]
                           config_value = Config.search(keys_specific) ||
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
            swipe_events = event_buffer.select { |event| event.record.gesture == GESTURE }
            return if swipe_events.empty?

            return if Generator.prev_vector && Generator.prev_vector != self

            move_x = swipe_events.avg_attrs(:move_x)
            move_y = swipe_events.avg_attrs(:move_y)
            new(swipe_events.finger, move_x, move_y).tap do |v|
              return nil unless v.enough?

              Generator.prev_vector = self
            end
          end
        end

        # direction of vector
        class Direction
          RIGHT = 'right'
          LEFT  = 'left'
          DOWN  = 'down'
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
              if @move_x > 0
                RIGHT
              else
                LEFT
              end
            elsif @move_y > 0
              DOWN
            else
              UP
            end
          end
        end

        # quantity of vector
        class Quantity
          def initialize(move_x:, move_y:)
            @x = move_x.abs
            @y = move_y.abs
          end

          def to_f
            calc.to_f
          end

          def calc
            if @x > @y
              @x.abs
            else
              @y.abs
            end
          end
        end
      end
    end
  end
end
