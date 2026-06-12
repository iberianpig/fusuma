# frozen_string_literal: true

require "spec_helper"
require "fiddle"
require "./lib/fusuma/libinput/constants"
require "./lib/fusuma/device"

# Stub Functions module before loading
module Fusuma
  module Libinput
    module Functions
      unless respond_to?(:stub_function)
        def self.stub_function
          obj = Object.new
          def obj.call(*args)
          end
          obj
        end
      end

      # Only define constants that haven't been defined yet
      %w[
        PATH_CREATE_CONTEXT PATH_ADD_DEVICE GET_FD DISPATCH GET_EVENT UNREF
        EVENT_GET_TYPE EVENT_GET_DEVICE EVENT_DESTROY
        DEVICE_GET_NAME DEVICE_GET_SYSNAME DEVICE_HAS_CAPABILITY
      ].each do |name|
        const_set(name, stub_function) unless const_defined?(name)
      end
    end
  end
end

require "./lib/fusuma/libinput/interface"
require "./lib/fusuma/libinput/context"
require "./lib/fusuma/libinput/device_detector"

module Fusuma
  module Libinput
    RSpec.describe DeviceDetector do
      let(:detector) { described_class.new }
      let(:context_ptr) { Fiddle::Pointer.malloc(8) }
      let(:device_ptr) { Fiddle::Pointer.malloc(8) }
      let(:null_ptr) { Fiddle::Pointer.new(0) }
      let(:event_ptr) { Fiddle::Pointer.malloc(8) }

      before do
        allow(Functions::PATH_CREATE_CONTEXT).to receive(:call).and_return(context_ptr)
        allow(Functions::DISPATCH).to receive(:call).and_return(0)
        allow(Functions::UNREF).to receive(:call).and_return(null_ptr)
        allow(detector).to receive(:event_device_paths)
          .and_return(["/dev/input/event0", "/dev/input/event1"])
      end

      describe "#detect" do
        context "when devices with gesture capability exist" do
          before do
            allow(Functions::PATH_ADD_DEVICE).to receive(:call).and_return(device_ptr)
            allow(Functions::GET_EVENT).to receive(:call)
              .and_return(event_ptr, null_ptr)
            allow(Functions::EVENT_GET_TYPE).to receive(:call)
              .and_return(Constants::DEVICE_ADDED)
            allow(Functions::EVENT_GET_DEVICE).to receive(:call)
              .and_return(device_ptr)
            allow(Functions::EVENT_DESTROY).to receive(:call)

            name_ptr = Fiddle::Pointer.to_ptr("My Touchpad\0")
            sysname_ptr = Fiddle::Pointer.to_ptr("event4\0")
            allow(Functions::DEVICE_GET_NAME).to receive(:call).and_return(name_ptr)
            allow(Functions::DEVICE_GET_SYSNAME).to receive(:call).and_return(sysname_ptr)
            allow(Functions::DEVICE_HAS_CAPABILITY).to receive(:call) do |_dev, cap|
              case cap
              when Constants::DEVICE_CAP_GESTURE then 1
              when Constants::DEVICE_CAP_POINTER then 1
              else 0
              end
            end
          end

          it "returns devices with gesture capability" do
            devices = detector.detect
            expect(devices.length).to eq(1)
            expect(devices.first.name).to eq("My Touchpad")
            expect(devices.first.id).to eq("event4")
            expect(devices.first.available).to be true
            expect(devices.first.capabilities).to include("gesture")
            expect(devices.first.capabilities).to include("pointer")
          end
        end

        context "when no gesture devices exist" do
          before do
            allow(Functions::PATH_ADD_DEVICE).to receive(:call).and_return(device_ptr)
            allow(Functions::GET_EVENT).to receive(:call)
              .and_return(event_ptr, null_ptr)
            allow(Functions::EVENT_GET_TYPE).to receive(:call)
              .and_return(Constants::DEVICE_ADDED)
            allow(Functions::EVENT_GET_DEVICE).to receive(:call)
              .and_return(device_ptr)
            allow(Functions::EVENT_DESTROY).to receive(:call)

            name_ptr = Fiddle::Pointer.to_ptr("Keyboard\0")
            sysname_ptr = Fiddle::Pointer.to_ptr("event0\0")
            allow(Functions::DEVICE_GET_NAME).to receive(:call).and_return(name_ptr)
            allow(Functions::DEVICE_GET_SYSNAME).to receive(:call).and_return(sysname_ptr)
            allow(Functions::DEVICE_HAS_CAPABILITY).to receive(:call) do |_dev, cap|
              case cap
              when Constants::DEVICE_CAP_KEYBOARD then 1
              else 0
              end
            end
          end

          it "returns device with available=false" do
            devices = detector.detect
            expect(devices.length).to eq(1)
            expect(devices.first.available).to be false
          end
        end
      end
    end
  end
end
