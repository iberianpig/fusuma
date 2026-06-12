# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/libinput/constants"
require "./lib/fusuma/plugin/events/records/touch_record"
require "./lib/fusuma/libinput/touch_event"

module Fusuma
  module Libinput
    RSpec.describe TouchEvent do
      let(:event_ptr) { Object.new }
      let(:touch_ptr) { Object.new }
      let(:get_x) { double("TOUCH_GET_X", call: 51.3) }
      let(:get_y) { double("TOUCH_GET_Y", call: 42.1) }

      before do
        stub_const("Fusuma::Libinput::Functions::EVENT_GET_TOUCH_EVENT",
          double(call: touch_ptr))
        stub_const("Fusuma::Libinput::Functions::TOUCH_GET_SLOT", double(call: 1))
        stub_const("Fusuma::Libinput::Functions::TOUCH_GET_X", get_x)
        stub_const("Fusuma::Libinput::Functions::TOUCH_GET_Y", get_y)
      end

      context "with TOUCH_DOWN" do
        it "extracts slot and position" do
          event = described_class.new(event_ptr: event_ptr, event_type: Constants::TOUCH_DOWN)
          record = event.to_touch_record

          expect(record).to be_a(Plugin::Events::Records::TouchRecord)
          expect(record.status).to eq("down")
          expect(record.slot).to eq(1)
          expect(record.x_mm).to eq(51.3)
          expect(record.y_mm).to eq(42.1)
        end
      end

      context "with TOUCH_UP" do
        # x/y are only valid for down/motion; strict doubles fail if called
        let(:get_x) { double("TOUCH_GET_X") }
        let(:get_y) { double("TOUCH_GET_Y") }

        it "does not query position" do
          event = described_class.new(event_ptr: event_ptr, event_type: Constants::TOUCH_UP)

          expect(event.status).to eq("up")
          expect(event.slot).to eq(1)
          expect(event.x_mm).to be_nil
        end
      end

      context "with TOUCH_FRAME" do
        it "has no slot" do
          event = described_class.new(event_ptr: event_ptr, event_type: Constants::TOUCH_FRAME)

          expect(event.status).to eq("frame")
          expect(event.slot).to be_nil
        end
      end
    end
  end
end
