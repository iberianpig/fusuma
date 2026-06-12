# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/libinput/constants"
require "./lib/fusuma/plugin/events/records/pointer_record"
require "./lib/fusuma/libinput/pointer_event"

module Fusuma
  module Libinput
    RSpec.describe PointerEvent do
      let(:event_ptr) { Object.new }
      let(:pointer_ptr) { Object.new }

      before do
        stub_const("Fusuma::Libinput::Functions::EVENT_GET_POINTER_EVENT",
          double(call: pointer_ptr))
      end

      context "with POINTER_MOTION" do
        before do
          stub_const("Fusuma::Libinput::Functions::POINTER_GET_DX", double(call: 2.5))
          stub_const("Fusuma::Libinput::Functions::POINTER_GET_DY", double(call: -1.0))
        end

        it "extracts deltas" do
          record = described_class.new(
            event_ptr: event_ptr, event_type: Constants::POINTER_MOTION
          ).to_pointer_record

          expect(record.status).to eq("motion")
          expect(record.dx).to eq(2.5)
          expect(record.dy).to eq(-1.0)
        end
      end

      context "with POINTER_BUTTON" do
        before do
          stub_const("Fusuma::Libinput::Functions::POINTER_GET_BUTTON", double(call: 0x110))
          stub_const("Fusuma::Libinput::Functions::POINTER_GET_BUTTON_STATE", double(call: 1))
        end

        it "extracts button and state" do
          record = described_class.new(
            event_ptr: event_ptr, event_type: Constants::POINTER_BUTTON
          ).to_pointer_record

          expect(record.status).to eq("button")
          expect(record.button).to eq(0x110)
          expect(record.button_state).to eq(1)
        end
      end

      context "with POINTER_SCROLL_FINGER" do
        before do
          has_axis = double("POINTER_HAS_AXIS")
          allow(has_axis).to receive(:call)
            .with(pointer_ptr, Constants::POINTER_AXIS_SCROLL_VERTICAL).and_return(1)
          allow(has_axis).to receive(:call)
            .with(pointer_ptr, Constants::POINTER_AXIS_SCROLL_HORIZONTAL).and_return(0)
          stub_const("Fusuma::Libinput::Functions::POINTER_HAS_AXIS", has_axis)
          stub_const("Fusuma::Libinput::Functions::POINTER_GET_SCROLL_VALUE",
            double(call: 15.0))
        end

        it "extracts only the axes the event has" do
          record = described_class.new(
            event_ptr: event_ptr, event_type: Constants::POINTER_SCROLL_FINGER
          ).to_pointer_record

          expect(record.status).to eq("scroll_finger")
          expect(record.vertical).to eq(15.0)
          expect(record.horizontal).to be_nil
        end
      end
    end
  end
end
