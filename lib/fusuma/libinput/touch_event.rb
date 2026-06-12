# frozen_string_literal: true

require_relative "../plugin/events/records/touch_record"

module Fusuma
  module Libinput
    # Extracts touch data from a libinput event pointer and converts to TouchRecord
    class TouchEvent
      # statuses for which libinput reports a position
      POSITION_STATUSES = %w[down motion].freeze

      attr_reader :status, :slot, :x_mm, :y_mm

      # @param event_ptr [Fiddle::Pointer]
      # @param event_type [Integer]
      #: (event_ptr: Fiddle::Pointer, event_type: Integer) -> void
      def initialize(event_ptr:, event_type:)
        status = Constants::TOUCH_STATUS_MAP[event_type]
        raise "Unknown touch event type: #{event_type}" unless status

        @status = status
        touch_ptr = Functions::EVENT_GET_TOUCH_EVENT.call(event_ptr)

        # slot is not valid for TOUCH_FRAME
        @slot = (Functions::TOUCH_GET_SLOT.call(touch_ptr) unless @status == "frame")

        # x/y are only valid for TOUCH_DOWN and TOUCH_MOTION
        if POSITION_STATUSES.include?(@status)
          @x_mm = Functions::TOUCH_GET_X.call(touch_ptr)
          @y_mm = Functions::TOUCH_GET_Y.call(touch_ptr)
        end
      end

      #: () -> Fusuma::Plugin::Events::Records::TouchRecord
      def to_touch_record
        Plugin::Events::Records::TouchRecord.new(
          status: @status, slot: @slot, x_mm: @x_mm, y_mm: @y_mm
        )
      end
    end
  end
end
