# frozen_string_literal: true

module Fusuma
  module Plugin
    module Formats
      module Records
        # Gesture Record Format
        class GestureRecord < Record
          # define gesture format
          attr_reader :status, :gesture, :finger, :direction

          Direction = Struct.new(:move_x, :move_y, :zoom, :rotate)

          # @param status [String]
          def initialize(status:, gesture:, finger:, direction:)
            @status  = status
            @gesture = gesture
            @finger  = finger
            @direction = direction
          end

          def type
            :gesture
          end
        end
      end
    end
  end
end
