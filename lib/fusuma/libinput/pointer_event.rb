# frozen_string_literal: true

require_relative "../plugin/events/records/pointer_record"

module Fusuma
  module Libinput
    # Extracts pointer data from a libinput event pointer and converts to PointerRecord
    class PointerEvent
      attr_reader :status, :dx, :dy, :button, :button_state, :vertical, :horizontal

      # @param event_ptr [Fiddle::Pointer]
      # @param event_type [Integer]
      #: (event_ptr: Fiddle::Pointer, event_type: Integer) -> void
      def initialize(event_ptr:, event_type:)
        status = Constants::POINTER_STATUS_MAP[event_type]
        raise "Unknown pointer event type: #{event_type}" unless status

        @status = status
        pointer_ptr = Functions::EVENT_GET_POINTER_EVENT.call(event_ptr)

        case @status
        when "motion"
          @dx = Functions::POINTER_GET_DX.call(pointer_ptr)
          @dy = Functions::POINTER_GET_DY.call(pointer_ptr)
        when "button"
          @button = Functions::POINTER_GET_BUTTON.call(pointer_ptr)
          @button_state = Functions::POINTER_GET_BUTTON_STATE.call(pointer_ptr)
        else # scroll_*
          @vertical = scroll_value(pointer_ptr, Constants::POINTER_AXIS_SCROLL_VERTICAL)
          @horizontal = scroll_value(pointer_ptr, Constants::POINTER_AXIS_SCROLL_HORIZONTAL)
        end
      end

      #: () -> Fusuma::Plugin::Events::Records::PointerRecord
      def to_pointer_record
        Plugin::Events::Records::PointerRecord.new(
          status: @status,
          dx: @dx, dy: @dy,
          button: @button, button_state: @button_state,
          vertical: @vertical, horizontal: @horizontal
        )
      end

      private

      # Querying an axis the event does not have is a libinput client bug,
      # so check has_axis first
      #: (Fiddle::Pointer, Integer) -> Float?
      def scroll_value(pointer_ptr, axis)
        return nil unless Functions::POINTER_GET_SCROLL_VALUE
        return nil if Functions::POINTER_HAS_AXIS.call(pointer_ptr, axis).zero?

        Functions::POINTER_GET_SCROLL_VALUE.call(pointer_ptr, axis)
      end
    end
  end
end
