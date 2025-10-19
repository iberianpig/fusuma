# frozen_string_literal: true

require_relative "text_record"

module Fusuma
  module Plugin
    module Events
      module Records
        # Gesture Record
        class GestureRecord < Record
          # define gesture format
          attr_reader :status, :gesture, :finger, :delta

          Delta = Struct.new(
            :move_x, :move_y,
            :unaccelerated_x, :unaccelerated_y,
            :zoom,
            :rotate
          )

          # @param status [String]
          # @param gesture [String]
          # @param finger [String, Integer]
          # @param delta [Delta, NilClass]
          #: (status: String, gesture: String, finger: Integer | String, delta: Fusuma::Plugin::Events::Records::GestureRecord::Delta | nil) -> void
          def initialize(status:, gesture:, finger:, delta:)
            super()
            @status = status
            @gesture = gesture
            @finger = finger.to_i
            @delta = delta
          end

          #: () -> String
          def to_s
            "#{@gesture}, Finger: #{@finger}, Status: #{@status}"
          end
        end
      end
    end
  end
end
