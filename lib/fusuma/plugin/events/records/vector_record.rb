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

          # @param gesture [String]
          # @param finger [String]
          # @param quantity [String]
          def initialize(gesture:, finger:, direction:, quantity:)
            @gesture = gesture
            @finger  = finger.to_i
            @direction = direction
            @quantity = quantity
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
