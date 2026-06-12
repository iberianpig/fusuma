# frozen_string_literal: true

require "fiddle"

module Fusuma
  module Libinput
    # Fiddle::Function definitions for libinput C API
    module Functions
      # Shorthand type aliases
      VOID = Fiddle::TYPE_VOID
      VOIDP = Fiddle::TYPE_VOIDP
      INT = Fiddle::TYPE_INT
      # Fiddle has no unsigned int type; INT works since enum values fit in signed range
      ENUM = Fiddle::TYPE_INT
      DOUBLE = Fiddle::TYPE_DOUBLE

      # Context creation/destruction
      # struct libinput *libinput_path_create_context(
      #   const struct libinput_interface *interface, void *user_data)
      PATH_CREATE_CONTEXT = Fiddle::Function.new(
        LIB["libinput_path_create_context"],
        [VOIDP, VOIDP], VOIDP
      )

      # struct libinput *libinput_udev_create_context(
      #   const struct libinput_interface *interface, void *user_data,
      #   struct udev *udev)
      UDEV_CREATE_CONTEXT = Fiddle::Function.new(
        LIB["libinput_udev_create_context"],
        [VOIDP, VOIDP, VOIDP], VOIDP
      )

      # int libinput_udev_assign_seat(struct libinput *libinput, const char *seat_id)
      UDEV_ASSIGN_SEAT = Fiddle::Function.new(
        LIB["libinput_udev_assign_seat"],
        [VOIDP, VOIDP], INT
      )

      # struct libinput_device *libinput_path_add_device(
      #   struct libinput *libinput, const char *path)
      PATH_ADD_DEVICE = Fiddle::Function.new(
        LIB["libinput_path_add_device"],
        [VOIDP, VOIDP], VOIDP
      )

      # void libinput_path_remove_device(struct libinput_device *device)
      PATH_REMOVE_DEVICE = Fiddle::Function.new(
        LIB["libinput_path_remove_device"],
        [VOIDP], VOID
      )

      # int libinput_get_fd(struct libinput *libinput)
      GET_FD = Fiddle::Function.new(
        LIB["libinput_get_fd"],
        [VOIDP], INT
      )

      # int libinput_dispatch(struct libinput *libinput)
      DISPATCH = Fiddle::Function.new(
        LIB["libinput_dispatch"],
        [VOIDP], INT
      )

      # struct libinput_event *libinput_get_event(struct libinput *libinput)
      GET_EVENT = Fiddle::Function.new(
        LIB["libinput_get_event"],
        [VOIDP], VOIDP
      )

      # struct libinput *libinput_unref(struct libinput *libinput)
      UNREF = Fiddle::Function.new(
        LIB["libinput_unref"],
        [VOIDP], VOIDP
      )

      # Event functions
      # enum libinput_event_type libinput_event_get_type(struct libinput_event *event)
      EVENT_GET_TYPE = Fiddle::Function.new(
        LIB["libinput_event_get_type"],
        [VOIDP], ENUM
      )

      # struct libinput_event_gesture *libinput_event_get_gesture_event(
      #   struct libinput_event *event)
      EVENT_GET_GESTURE_EVENT = Fiddle::Function.new(
        LIB["libinput_event_get_gesture_event"],
        [VOIDP], VOIDP
      )

      # struct libinput_device *libinput_event_get_device(struct libinput_event *event)
      EVENT_GET_DEVICE = Fiddle::Function.new(
        LIB["libinput_event_get_device"],
        [VOIDP], VOIDP
      )

      # void libinput_event_destroy(struct libinput_event *event)
      EVENT_DESTROY = Fiddle::Function.new(
        LIB["libinput_event_destroy"],
        [VOIDP], VOID
      )

      # Gesture event functions
      # int libinput_event_gesture_get_finger_count(
      #   struct libinput_event_gesture *event)
      GESTURE_GET_FINGER_COUNT = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_finger_count"],
        [VOIDP], INT
      )

      # double libinput_event_gesture_get_dx(struct libinput_event_gesture *event)
      GESTURE_GET_DX = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_dx"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_gesture_get_dy(struct libinput_event_gesture *event)
      GESTURE_GET_DY = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_dy"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_gesture_get_dx_unaccelerated(
      #   struct libinput_event_gesture *event)
      GESTURE_GET_DX_UNACCELERATED = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_dx_unaccelerated"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_gesture_get_dy_unaccelerated(
      #   struct libinput_event_gesture *event)
      GESTURE_GET_DY_UNACCELERATED = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_dy_unaccelerated"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_gesture_get_scale(struct libinput_event_gesture *event)
      GESTURE_GET_SCALE = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_scale"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_gesture_get_angle_delta(
      #   struct libinput_event_gesture *event)
      GESTURE_GET_ANGLE_DELTA = Fiddle::Function.new(
        LIB["libinput_event_gesture_get_angle_delta"],
        [VOIDP], DOUBLE
      )

      # int libinput_event_gesture_get_cancelled(struct libinput_event_gesture *event)
      # Available since libinput 1.19
      GESTURE_GET_CANCELLED = begin
        Fiddle::Function.new(
          LIB["libinput_event_gesture_get_cancelled"],
          [VOIDP], INT
        )
      rescue Fiddle::DLError
        nil
      end

      # Touch event functions
      # struct libinput_event_touch *libinput_event_get_touch_event(
      #   struct libinput_event *event)
      EVENT_GET_TOUCH_EVENT = Fiddle::Function.new(
        LIB["libinput_event_get_touch_event"],
        [VOIDP], VOIDP
      )

      # int32_t libinput_event_touch_get_slot(struct libinput_event_touch *event)
      TOUCH_GET_SLOT = Fiddle::Function.new(
        LIB["libinput_event_touch_get_slot"],
        [VOIDP], INT
      )

      # double libinput_event_touch_get_x(struct libinput_event_touch *event)
      TOUCH_GET_X = Fiddle::Function.new(
        LIB["libinput_event_touch_get_x"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_touch_get_y(struct libinput_event_touch *event)
      TOUCH_GET_Y = Fiddle::Function.new(
        LIB["libinput_event_touch_get_y"],
        [VOIDP], DOUBLE
      )

      # Pointer event functions
      # struct libinput_event_pointer *libinput_event_get_pointer_event(
      #   struct libinput_event *event)
      EVENT_GET_POINTER_EVENT = Fiddle::Function.new(
        LIB["libinput_event_get_pointer_event"],
        [VOIDP], VOIDP
      )

      # double libinput_event_pointer_get_dx(struct libinput_event_pointer *event)
      POINTER_GET_DX = Fiddle::Function.new(
        LIB["libinput_event_pointer_get_dx"],
        [VOIDP], DOUBLE
      )

      # double libinput_event_pointer_get_dy(struct libinput_event_pointer *event)
      POINTER_GET_DY = Fiddle::Function.new(
        LIB["libinput_event_pointer_get_dy"],
        [VOIDP], DOUBLE
      )

      # uint32_t libinput_event_pointer_get_button(struct libinput_event_pointer *event)
      POINTER_GET_BUTTON = Fiddle::Function.new(
        LIB["libinput_event_pointer_get_button"],
        [VOIDP], INT
      )

      # enum libinput_button_state libinput_event_pointer_get_button_state(
      #   struct libinput_event_pointer *event)
      POINTER_GET_BUTTON_STATE = Fiddle::Function.new(
        LIB["libinput_event_pointer_get_button_state"],
        [VOIDP], ENUM
      )

      # int libinput_event_pointer_has_axis(
      #   struct libinput_event_pointer *event, enum libinput_pointer_axis axis)
      POINTER_HAS_AXIS = Fiddle::Function.new(
        LIB["libinput_event_pointer_has_axis"],
        [VOIDP, ENUM], INT
      )

      # double libinput_event_pointer_get_scroll_value(
      #   struct libinput_event_pointer *event, enum libinput_pointer_axis axis)
      # Available since libinput 1.19 (POINTER_SCROLL_* events appeared together)
      POINTER_GET_SCROLL_VALUE = begin
        Fiddle::Function.new(
          LIB["libinput_event_pointer_get_scroll_value"],
          [VOIDP, ENUM], DOUBLE
        )
      rescue Fiddle::DLError
        nil
      end

      # Device functions
      # const char *libinput_device_get_name(struct libinput_device *device)
      DEVICE_GET_NAME = Fiddle::Function.new(
        LIB["libinput_device_get_name"],
        [VOIDP], VOIDP
      )

      # const char *libinput_device_get_sysname(struct libinput_device *device)
      DEVICE_GET_SYSNAME = Fiddle::Function.new(
        LIB["libinput_device_get_sysname"],
        [VOIDP], VOIDP
      )

      # int libinput_device_has_capability(struct libinput_device *device,
      #   enum libinput_device_capability cap)
      DEVICE_HAS_CAPABILITY = Fiddle::Function.new(
        LIB["libinput_device_has_capability"],
        [VOIDP, INT], INT
      )

      # Device config functions (equivalents of the libinput CLI options)
      # enum libinput_config_status libinput_device_config_tap_set_enabled(
      #   struct libinput_device *device, enum libinput_config_tap_state enable)
      TAP_SET_ENABLED = Fiddle::Function.new(
        LIB["libinput_device_config_tap_set_enabled"],
        [VOIDP, ENUM], ENUM
      )

      # enum libinput_config_tap_state libinput_device_config_tap_get_enabled(
      #   struct libinput_device *device)
      TAP_GET_ENABLED = Fiddle::Function.new(
        LIB["libinput_device_config_tap_get_enabled"],
        [VOIDP], ENUM
      )

      # enum libinput_config_status libinput_device_config_dwt_set_enabled(
      #   struct libinput_device *device, enum libinput_config_dwt_state enable)
      DWT_SET_ENABLED = Fiddle::Function.new(
        LIB["libinput_device_config_dwt_set_enabled"],
        [VOIDP, ENUM], ENUM
      )

      # enum libinput_config_dwt_state libinput_device_config_dwt_get_enabled(
      #   struct libinput_device *device)
      DWT_GET_ENABLED = Fiddle::Function.new(
        LIB["libinput_device_config_dwt_get_enabled"],
        [VOIDP], ENUM
      )

      # enum libinput_config_status libinput_device_config_send_events_set_mode(
      #   struct libinput_device *device, uint32_t mode)
      SEND_EVENTS_SET_MODE = Fiddle::Function.new(
        LIB["libinput_device_config_send_events_set_mode"],
        [VOIDP, INT], ENUM
      )

      # udev functions
      # struct udev *udev_new(void)
      UDEV_NEW = Fiddle::Function.new(
        UDEV_LIB["udev_new"],
        [], VOIDP
      )

      # struct udev *udev_unref(struct udev *udev)
      UDEV_UNREF = Fiddle::Function.new(
        UDEV_LIB["udev_unref"],
        [VOIDP], VOIDP
      )
    end
  end
end
