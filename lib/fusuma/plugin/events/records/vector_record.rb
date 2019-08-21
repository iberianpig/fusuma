# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        # Vector Record
        # have index
        class VectorRecord < Record
          # define gesture format
          attr_reader :gesture, :finger, :direction, :quantity

          # @param [String] gesture
          # @param [String] finger
          # @param [String] direction
          # @param [Float] quantity
          # @param [Config::Index] index
          def initialize(gesture:, finger:, direction:, quantity: nil, index: nil)
            @gesture = gesture
            @finger  = finger.to_i
            @direction = direction
            @quantity = quantity
            @index = index
          end

          def type
            :vector
          end

          # @return [Config::Index]
          def index
            @index ||= Config::Index.new(
              [
                Config::Index::Key.new(gesture),
                Config::Index::Key.new(finger, skippable: true),
                Config::Index::Key.new(direction)
              ]
            )
          end
        end
      end
    end
  end
end
