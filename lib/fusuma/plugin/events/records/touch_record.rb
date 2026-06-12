# frozen_string_literal: true

require_relative "record"

module Fusuma
  module Plugin
    module Events
      module Records
        # Touch event from a touchscreen (one record per touch point update)
        class TouchRecord < Record
          attr_reader :status, :slot, :x_mm, :y_mm

          # @param status [String] down / up / motion / cancel / frame
          # @param slot [Integer, nil] touch point id (nil for frame)
          # @param x_mm [Float, nil] absolute position (valid for down/motion)
          # @param y_mm [Float, nil]
          #: (status: String, slot: Integer?, ?x_mm: Float?, ?y_mm: Float?) -> void
          def initialize(status:, slot:, x_mm: nil, y_mm: nil)
            super()
            @status = status
            @slot = slot
            @x_mm = x_mm
            @y_mm = y_mm
          end

          #: () -> String
          def to_s
            "touch, Slot: #{@slot}, Status: #{@status}, Position: #{@x_mm}/#{@y_mm}"
          end
        end
      end
    end
  end
end
