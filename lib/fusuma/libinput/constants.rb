# frozen_string_literal: true

module Fusuma
  module Libinput
    # libinput event type constants
    module Constants
      # Device events
      DEVICE_ADDED = 1
      DEVICE_REMOVED = 2

      # Pointer events
      POINTER_MOTION = 400
      POINTER_MOTION_ABSOLUTE = 401
      POINTER_BUTTON = 402
      POINTER_AXIS = 403 # deprecated upstream; superseded by SCROLL_*
      POINTER_SCROLL_WHEEL = 404
      POINTER_SCROLL_FINGER = 405
      POINTER_SCROLL_CONTINUOUS = 406

      # Touch events
      TOUCH_DOWN = 500
      TOUCH_UP = 501
      TOUCH_MOTION = 502
      TOUCH_CANCEL = 503
      TOUCH_FRAME = 504

      # Maps event type to TouchRecord status
      TOUCH_STATUS_MAP = {
        TOUCH_DOWN => "down",
        TOUCH_UP => "up",
        TOUCH_MOTION => "motion",
        TOUCH_CANCEL => "cancel",
        TOUCH_FRAME => "frame"
      }.freeze

      # Maps event type to PointerRecord status.
      # POINTER_MOTION_ABSOLUTE and the deprecated POINTER_AXIS are
      # intentionally absent (AXIS would duplicate the SCROLL_* events).
      POINTER_STATUS_MAP = {
        POINTER_MOTION => "motion",
        POINTER_BUTTON => "button",
        POINTER_SCROLL_WHEEL => "scroll_wheel",
        POINTER_SCROLL_FINGER => "scroll_finger",
        POINTER_SCROLL_CONTINUOUS => "scroll_continuous"
      }.freeze

      # libinput_pointer_axis (for scroll value lookup)
      POINTER_AXIS_SCROLL_VERTICAL = 0
      POINTER_AXIS_SCROLL_HORIZONTAL = 1

      # Gesture events
      GESTURE_SWIPE_BEGIN = 800
      GESTURE_SWIPE_UPDATE = 801
      GESTURE_SWIPE_END = 802
      GESTURE_PINCH_BEGIN = 803
      GESTURE_PINCH_UPDATE = 804
      GESTURE_PINCH_END = 805
      GESTURE_HOLD_BEGIN = 806
      GESTURE_HOLD_END = 807

      # Device capabilities
      DEVICE_CAP_KEYBOARD = 0
      DEVICE_CAP_POINTER = 1
      DEVICE_CAP_TOUCH = 2
      DEVICE_CAP_TABLET_TOOL = 3
      DEVICE_CAP_TABLET_PAD = 4
      DEVICE_CAP_GESTURE = 5

      # libinput_config_send_events_mode
      SEND_EVENTS_ENABLED = 0
      SEND_EVENTS_DISABLED = 1

      # Capability name mapping for device detection
      CAPABILITY_MAP = {
        DEVICE_CAP_GESTURE => "gesture",
        DEVICE_CAP_POINTER => "pointer",
        DEVICE_CAP_KEYBOARD => "keyboard",
        DEVICE_CAP_TOUCH => "touch"
      }.freeze

      # Maps event type integer to [gesture, status]
      EVENT_TYPE_MAP = {
        GESTURE_SWIPE_BEGIN => ["swipe", "begin"].freeze,
        GESTURE_SWIPE_UPDATE => ["swipe", "update"].freeze,
        GESTURE_SWIPE_END => ["swipe", "end"].freeze,
        GESTURE_PINCH_BEGIN => ["pinch", "begin"].freeze,
        GESTURE_PINCH_UPDATE => ["pinch", "update"].freeze,
        GESTURE_PINCH_END => ["pinch", "end"].freeze,
        GESTURE_HOLD_BEGIN => ["hold", "begin"].freeze,
        GESTURE_HOLD_END => ["hold", "end"].freeze
      }.freeze

      # Gesture event type range for O(1) membership check
      GESTURE_EVENT_TYPE_RANGE = (GESTURE_SWIPE_BEGIN..GESTURE_HOLD_END).freeze
      DEVICE_EVENT_TYPES = [DEVICE_ADDED, DEVICE_REMOVED].freeze
    end
  end
end
