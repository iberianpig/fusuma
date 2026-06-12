# frozen_string_literal: true

require_relative "record"

module Fusuma
  module Plugin
    module Events
      module Records
        # Pointer event (motion / button / scroll) from a pointer device
        class PointerRecord < Record
          attr_reader :status, :dx, :dy, :button, :button_state,
            :vertical, :horizontal

          # @param status [String] motion / button / scroll_wheel /
          #   scroll_finger / scroll_continuous
          # @param dx [Float, nil] accelerated delta (motion)
          # @param dy [Float, nil]
          # @param button [Integer, nil] evdev button code (button)
          # @param button_state [Integer, nil] 1 pressed / 0 released
          # @param vertical [Float, nil] scroll amount (scroll_*)
          # @param horizontal [Float, nil]
          #: (status: String, ?dx: Float?, ?dy: Float?, ?button: Integer?, ?button_state: Integer?, ?vertical: Float?, ?horizontal: Float?) -> void
          def initialize(status:, dx: nil, dy: nil, button: nil, button_state: nil,
            vertical: nil, horizontal: nil)
            super()
            @status = status
            @dx = dx
            @dy = dy
            @button = button
            @button_state = button_state
            @vertical = vertical
            @horizontal = horizontal
          end

          #: () -> String
          def to_s
            "pointer, Status: #{@status}"
          end
        end
      end
    end
  end
end
