# frozen_string_literal: true

require "spec_helper"
require "fiddle"
require "./lib/fusuma/libinput/constants"

# Stub Functions constants if not already loaded (i.e. when libinput.so is not available)
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

      %w[
        PATH_CREATE_CONTEXT PATH_ADD_DEVICE PATH_REMOVE_DEVICE
        GET_FD DISPATCH GET_EVENT UNREF
        EVENT_GET_TYPE EVENT_GET_GESTURE_EVENT EVENT_GET_DEVICE EVENT_DESTROY
        UDEV_CREATE_CONTEXT UDEV_ASSIGN_SEAT UDEV_NEW UDEV_UNREF
      ].each do |name|
        const_set(name, stub_function) unless const_defined?(name)
      end
    end
  end
end

require "./lib/fusuma/libinput/context"

module Fusuma
  module Libinput
    RSpec.describe Context do
      let(:mock_ptr) { Fiddle::Pointer.malloc(16) }
      let(:interface) do
        iface = Interface.allocate
        iface.instance_variable_set(:@to_ptr, mock_ptr)
        iface
      end
      let(:context_ptr) { Fiddle::Pointer.malloc(8) }
      let(:device_ptr) { Fiddle::Pointer.malloc(8) }
      let(:null_ptr) { Fiddle::Pointer.new(0) }

      before do
        allow(Functions::PATH_CREATE_CONTEXT).to receive(:call).and_return(context_ptr)
      end

      describe "#initialize" do
        it "creates a context via path_create_context" do
          ctx = described_class.new(interface)
          expect(Functions::PATH_CREATE_CONTEXT).to have_received(:call)
            .with(mock_ptr, Fiddle::NULL)
          expect(ctx.ptr).to eq(context_ptr)
        end

        it "raises when context creation fails" do
          allow(Functions::PATH_CREATE_CONTEXT).to receive(:call).and_return(null_ptr)
          expect { described_class.new(interface) }.to raise_error(RuntimeError, /Failed to create/)
        end
      end

      describe "#add_device" do
        let(:ctx) { described_class.new(interface) }

        before do
          allow(Functions::PATH_ADD_DEVICE).to receive(:call).and_return(device_ptr)
        end

        it "adds a device and returns the device pointer" do
          result = ctx.add_device("/dev/input/event4")
          expect(Functions::PATH_ADD_DEVICE).to have_received(:call)
            .with(context_ptr, "/dev/input/event4")
          expect(result).to eq(device_ptr)
        end

        it "raises when device add fails" do
          allow(Functions::PATH_ADD_DEVICE).to receive(:call).and_return(null_ptr)
          expect { ctx.add_device("/dev/input/event99") }
            .to raise_error(RuntimeError, /Failed to add device/)
        end
      end

      describe "#fd" do
        it "returns file descriptor from get_fd" do
          ctx = described_class.new(interface)
          allow(Functions::GET_FD).to receive(:call).and_return(42)
          expect(ctx.fd).to eq(42)
        end
      end

      describe "#dispatch" do
        it "calls libinput_dispatch" do
          ctx = described_class.new(interface)
          allow(Functions::DISPATCH).to receive(:call).and_return(0)
          expect(ctx.dispatch).to eq(0)
        end
      end

      describe "#get_event" do
        let(:ctx) { described_class.new(interface) }
        let(:event_ptr) { Fiddle::Pointer.malloc(8) }

        it "returns event pointer when available" do
          allow(Functions::GET_EVENT).to receive(:call).and_return(event_ptr)
          expect(ctx.get_event).to eq(event_ptr)
        end

        it "returns nil when no more events" do
          allow(Functions::GET_EVENT).to receive(:call).and_return(null_ptr)
          expect(ctx.get_event).to be_nil
        end
      end

      describe "#each_event" do
        let(:ctx) { described_class.new(interface) }
        let(:event1) { Fiddle::Pointer.malloc(8) }
        let(:event2) { Fiddle::Pointer.malloc(8) }

        it "yields each event and destroys them" do
          allow(Functions::DISPATCH).to receive(:call).and_return(0)
          allow(Functions::GET_EVENT).to receive(:call)
            .and_return(event1, event2, null_ptr)
          allow(Functions::EVENT_DESTROY).to receive(:call)

          events = []
          ctx.each_event { |e| events << e }

          expect(events).to eq([event1, event2])
          expect(Functions::EVENT_DESTROY).to have_received(:call).with(event1)
          expect(Functions::EVENT_DESTROY).to have_received(:call).with(event2)
        end
      end

      describe "#destroy" do
        it "calls unref" do
          ctx = described_class.new(interface)
          allow(Functions::UNREF).to receive(:call).and_return(null_ptr)
          ctx.destroy
          expect(Functions::UNREF).to have_received(:call).with(context_ptr)
          expect(ctx.ptr).to be_nil
        end
      end
    end
  end
end
