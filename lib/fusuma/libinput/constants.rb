# frozen_string_literal: true

module Fusuma
  module Libinput
    # libinput event type constants
    module Constants
      # Device events
      DEVICE_ADDED = 1
      DEVICE_REMOVED = 2

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
