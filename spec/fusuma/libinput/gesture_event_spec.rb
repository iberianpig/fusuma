# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/libinput/constants"
require "./lib/fusuma/plugin/events/records/gesture_record"

# Load GestureEvent without requiring the full libinput FFI stack
require "./lib/fusuma/libinput/gesture_event"

module Fusuma
  module Libinput
    RSpec.describe GestureEvent do
      describe "keyword constructor (no FFI)" do
        let(:swipe_update) do
          described_class.new(
            gesture: "swipe",
            status: "update",
            finger_count: 3,
            dx: 10.5,
            dy: -2.3,
            dx_unaccelerated: 12.0,
            dy_unaccelerated: -3.0,
            scale: 1.0,
            angle_delta: 0.0
          )
        end

        it "stores all attributes" do
          expect(swipe_update.gesture).to eq("swipe")
          expect(swipe_update.status).to eq("update")
          expect(swipe_update.finger_count).to eq(3)
          expect(swipe_update.dx).to eq(10.5)
          expect(swipe_update.dy).to eq(-2.3)
          expect(swipe_update.dx_unaccelerated).to eq(12.0)
          expect(swipe_update.dy_unaccelerated).to eq(-3.0)
          expect(swipe_update.scale).to eq(1.0)
          expect(swipe_update.angle_delta).to eq(0.0)
          expect(swipe_update.cancelled).to be false
        end
      end

      describe "FFI extraction (stubbed Functions)" do
        let(:event_ptr) { Object.new }
        let(:gesture_ptr) { Object.new }

        let(:get_gesture_event) { double("EVENT_GET_GESTURE_EVENT", call: gesture_ptr) }
        let(:get_finger_count) { double("GESTURE_GET_FINGER_COUNT", call: 3) }
        let(:get_dx) { double("GESTURE_GET_DX", call: 5.0) }
        let(:get_dy) { double("GESTURE_GET_DY", call: -1.0) }
        let(:get_dx_unaccelerated) { double("GESTURE_GET_DX_UNACCELERATED", call: 6.0) }
        let(:get_dy_unaccelerated) { double("GESTURE_GET_DY_UNACCELERATED", call: -1.5) }
        # Strict doubles: calling an unstubbed method fails the example.
        # libinput_event_gesture_get_scale/angle_delta are only valid for
        # PINCH events; calling them for swipe/hold is a libinput client bug.
        let(:get_scale) { double("GESTURE_GET_SCALE") }
        let(:get_angle_delta) { double("GESTURE_GET_ANGLE_DELTA") }
        let(:get_cancelled) { double("GESTURE_GET_CANCELLED", call: 0) }

        before do
          stub_const("Fusuma::Libinput::Functions::EVENT_GET_GESTURE_EVENT", get_gesture_event)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_FINGER_COUNT", get_finger_count)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_DX", get_dx)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_DY", get_dy)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_DX_UNACCELERATED", get_dx_unaccelerated)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_DY_UNACCELERATED", get_dy_unaccelerated)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_SCALE", get_scale)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_ANGLE_DELTA", get_angle_delta)
          stub_const("Fusuma::Libinput::Functions::GESTURE_GET_CANCELLED", get_cancelled)
        end

        context "with swipe update" do
          it "fetches deltas but never queries pinch-only scale/angle" do
            event = described_class.new(event_ptr: event_ptr, event_type: Constants::GESTURE_SWIPE_UPDATE)
            expect(event.dx).to eq(5.0)
            expect(event.dy).to eq(-1.0)
            expect(event.dx_unaccelerated).to eq(6.0)
            expect(event.dy_unaccelerated).to eq(-1.5)
            expect(event.scale).to eq(1.0)
            expect(event.angle_delta).to eq(0.0)
          end
        end

        context "with swipe end" do
          it "does not query pinch-only scale" do
            event = described_class.new(event_ptr: event_ptr, event_type: Constants::GESTURE_SWIPE_END)
            expect(event.scale).to eq(1.0)
            expect(event.angle_delta).to eq(0.0)
          end
        end

        context "with hold end" do
          it "does not query pinch-only scale and reads cancelled state" do
            event = described_class.new(event_ptr: event_ptr, event_type: Constants::GESTURE_HOLD_END)
            expect(event.scale).to eq(1.0)
            expect(event.cancelled).to be false
          end
        end

        context "with pinch begin" do
          it "defaults scale to 1.0 without querying" do
            event = described_class.new(event_ptr: event_ptr, event_type: Constants::GESTURE_PINCH_BEGIN)
            expect(event.scale).to eq(1.0)
            expect(event.angle_delta).to eq(0.0)
          end
        end

        context "with pinch update" do
          before do
            allow(get_scale).to receive(:call).with(gesture_ptr).and_return(1.25)
            allow(get_angle_delta).to receive(:call).with(gesture_ptr).and_return(15.0)
          end

          it "queries scale and angle delta" do
            event = described_class.new(event_ptr: event_ptr, event_type: Constants::GESTURE_PINCH_UPDATE)
            expect(event.scale).to eq(1.25)
            expect(event.angle_delta).to eq(15.0)
          end
        end

        context "with pinch end" do
          before do
            allow(get_scale).to receive(:call).with(gesture_ptr).and_return(1.4)
          end

          it "queries the final scale but not angle delta" do
            event = described_class.new(event_ptr: event_ptr, event_type: Constants::GESTURE_PINCH_END)
            expect(event.scale).to eq(1.4)
            expect(event.angle_delta).to eq(0.0)
          end
        end
      end

      describe "#to_gesture_record" do
        context "with swipe update" do
          let(:event) do
            described_class.new(
              gesture: "swipe", status: "update", finger_count: 3,
              dx: 5.0, dy: -1.0,
              dx_unaccelerated: 6.0, dy_unaccelerated: -1.5,
              scale: 1.0, angle_delta: 0.0
            )
          end

          it "returns a GestureRecord with correct values" do
            record = event.to_gesture_record
            expect(record).to be_a(Plugin::Events::Records::GestureRecord)
            expect(record.gesture).to eq("swipe")
            expect(record.status).to eq("update")
            expect(record.finger).to eq(3)
            expect(record.delta.move_x).to eq(5.0)
            expect(record.delta.move_y).to eq(-1.0)
            expect(record.delta.unaccelerated_x).to eq(6.0)
            expect(record.delta.unaccelerated_y).to eq(-1.5)
            expect(record.delta.zoom).to eq(1.0)
            expect(record.delta.rotate).to eq(0.0)
          end
        end

        context "with pinch update" do
          let(:event) do
            described_class.new(
              gesture: "pinch", status: "update", finger_count: 2,
              dx: 0.0, dy: 0.0,
              dx_unaccelerated: 0.0, dy_unaccelerated: 0.0,
              scale: 1.25, angle_delta: 15.0
            )
          end

          it "returns a GestureRecord with scale and rotation" do
            record = event.to_gesture_record
            expect(record.gesture).to eq("pinch")
            expect(record.delta.zoom).to eq(1.25)
            expect(record.delta.rotate).to eq(15.0)
          end
        end

        context "with hold end (normal)" do
          let(:event) do
            described_class.new(
              gesture: "hold", status: "end", finger_count: 3,
              cancelled: false
            )
          end

          it "status is 'end'" do
            record = event.to_gesture_record
            expect(record.status).to eq("end")
          end
        end

        context "with hold end (cancelled)" do
          let(:event) do
            described_class.new(
              gesture: "hold", status: "end", finger_count: 3,
              cancelled: true
            )
          end

          it "status is 'cancelled'" do
            record = event.to_gesture_record
            expect(record.status).to eq("cancelled")
          end
        end

        context "with swipe begin" do
          let(:event) do
            described_class.new(
              gesture: "swipe", status: "begin", finger_count: 4
            )
          end

          it "has zero deltas" do
            record = event.to_gesture_record
            expect(record.status).to eq("begin")
            expect(record.delta.move_x).to eq(0.0)
            expect(record.delta.move_y).to eq(0.0)
          end
        end
      end
    end
  end
end
