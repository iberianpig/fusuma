# frozen_string_literal: true

require "fiddle"
require "fiddle/import"

module Fusuma
  module Libinput
    LIB = begin
      Fiddle.dlopen("libinput.so.10")
    rescue Fiddle::DLError
      Fiddle.dlopen("libinput.so")
    end

    UDEV_LIB = begin
      Fiddle.dlopen("libudev.so.1")
    rescue Fiddle::DLError
      Fiddle.dlopen("libudev.so")
    end
  end
end

require_relative "constants"
require_relative "functions"
require_relative "interface"
require_relative "context"
require_relative "gesture_event"
require_relative "touch_event"
require_relative "pointer_event"
require_relative "device_detector"
