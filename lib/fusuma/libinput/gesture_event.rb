# frozen_string_literal: true

require_relative "../plugin/events/records/gesture_record"

module Fusuma
  module Libinput
    # Extracts gesture data from a libinput event pointer and converts to GestureRecord
    class GestureEvent
      attr_reader :gesture, :status, :finger_count,
        :dx, :dy, :dx_unaccelerated, :dy_unaccelerated,
        :scale, :angle_delta, :cancelled

      # Build from a raw libinput event pointer
      # @param event_ptr [Fiddle::Pointer]
      # @param event_type [Integer]
      #: (?event_ptr: Fiddle::Pointer?, ?event_type: Integer?, ?gesture: String?, ?status: String?, ?finger_count: Integer?, ?dx: Float, ?dy: Float, ?dx_unaccelerated: Float, ?dy_unaccelerated: Float, ?scale: Float, ?angle_delta: Float, ?cancelled: bool) -> void
      def initialize(event_ptr: nil, event_type: nil,
        gesture: nil, status: nil, finger_count: nil,
        dx: 0.0, dy: 0.0, dx_unaccelerated: 0.0, dy_unaccelerated: 0.0,
        scale: 1.0, angle_delta: 0.0, cancelled: false)
        if event_ptr && event_type
          extract_from_ptr(event_ptr, event_type)
        else
          @gesture = gesture
          @status = status
          @finger_count = finger_count
          @dx = dx
          @dy = dy
          @dx_unaccelerated = dx_unaccelerated
          @dy_unaccelerated = dy_unaccelerated
          @scale = scale
          @angle_delta = angle_delta
          @cancelled = cancelled
        end
      end

      # @return [Plugin::Events::Records::GestureRecord]
      #: () -> Fusuma::Plugin::Events::Records::GestureRecord
      def to_gesture_record
        delta = Plugin::Events::Records::GestureRecord::Delta.new(
          @dx, @dy,
          @dx_unaccelerated, @dy_unaccelerated,
          @scale, @angle_delta
        )

        resolved_status = if @gesture == "hold" && @status == "end" && @cancelled
          "cancelled"
        else
          @status
        end

        Plugin::Events::Records::GestureRecord.new(
          status: resolved_status,
          gesture: @gesture,
          finger: @finger_count,
          delta: delta
        )
      end

      private

      #: (Fiddle::Pointer, Integer) -> bool
      def extract_from_ptr(event_ptr, event_type)
        gesture_status = Constants::EVENT_TYPE_MAP[event_type]
        raise "Unknown gesture event type: #{event_type}" unless gesture_status

        @gesture = gesture_status[0]
        @status = gesture_status[1]

        gesture_ptr = Functions::EVENT_GET_GESTURE_EVENT.call(event_ptr)
        @finger_count = Functions::GESTURE_GET_FINGER_COUNT.call(gesture_ptr)

        # dx/dy are only valid for SWIPE_UPDATE / PINCH_UPDATE
        if @status == "update"
          @dx = Functions::GESTURE_GET_DX.call(gesture_ptr)
          @dy = Functions::GESTURE_GET_DY.call(gesture_ptr)
          @dx_unaccelerated = Functions::GESTURE_GET_DX_UNACCELERATED.call(gesture_ptr)
          @dy_unaccelerated = Functions::GESTURE_GET_DY_UNACCELERATED.call(gesture_ptr)
        else
          @dx = 0.0
          @dy = 0.0
          @dx_unaccelerated = 0.0
          @dy_unaccelerated = 0.0
        end

        # scale/angle_delta are only valid for PINCH events; calling them
        # for swipe/hold is a libinput client bug
        if @gesture == "pinch"
          @scale = (@status == "begin") ? 1.0 : Functions::GESTURE_GET_SCALE.call(gesture_ptr)
          @angle_delta = (@status == "update") ? Functions::GESTURE_GET_ANGLE_DELTA.call(gesture_ptr) : 0.0
        else
          @scale = 1.0
          @angle_delta = 0.0
        end

        @cancelled = if @gesture == "hold" && @status == "end" && Functions::GESTURE_GET_CANCELLED
          Functions::GESTURE_GET_CANCELLED.call(gesture_ptr) != 0
        else
          false
        end
      end
    end
  end
end
