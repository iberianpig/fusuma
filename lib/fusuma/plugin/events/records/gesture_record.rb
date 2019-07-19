# frozen_string_literal: true

require_relative './text_record.rb'

module Fusuma
  module Plugin
    module Events
      module Records
        # Gesture Record
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
