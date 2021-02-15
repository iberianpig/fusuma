# frozen_string_literal: true

require_relative './text_record'

module Fusuma
  module Plugin
    module Events
      module Records
        # Gesture Record
        class GestureRecord < Record
          # define gesture format
          attr_reader :status, :gesture, :finger, :direction

          Delta = Struct.new(:move_x, :move_y,
                             :unaccelerated_x, :unaccelerated_y,
                             :zoom, :rotate)

          # @param status [String]
          # @param gesture [String]
          # @param finger [String, Integer]
          # @param direction [Delta, NilClass]
          def initialize(status:, gesture:, finger:, direction:)
            super()
            @status  = status
            @gesture = gesture
            @finger  = finger.to_i
            @direction = direction
          end
        end
      end
    end
  end
end
