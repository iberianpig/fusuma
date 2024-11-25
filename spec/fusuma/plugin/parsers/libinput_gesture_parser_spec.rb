# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/parsers/parser"
require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/plugin/inputs/input"

module Fusuma
  module Plugin
    module Parsers
      RSpec.describe LibinputGestureParser do
        let(:parser) { LibinputGestureParser.new }

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
             parsers:
               libinput_gesture_parser:
                 dummy: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe "#source" do
          subject { parser.source }

          it { is_expected.to be LibinputGestureParser::DEFAULT_SOURCE }
        end

        describe "#parse" do
          context "with different tag(dummy) event" do
            let(:event) { Events::Event.new(tag: "dummy_input", record: "dummy") }
            it { expect(parser.parse(event).record).not_to be_a Events::Records::GestureRecord }
            it { expect(parser.parse(event)).to eq event }
          end

          context "with libinput version 1.27.0 or later" do
            before do
              allow_any_instance_of(LibinputCommand).to receive(:libinput_1_27_0_or_later?).and_return(true)
            end

            context "with swipe gestures" do
              before do
                @debug_events = <<~EVENTS
                  event4   GESTURE_SWIPE_BEGIN         +19.410s  3
                  event4   GESTURE_SWIPE_UPDATE        +19.410s  3 19.02/ 1.00 ( 4.17/ 0.22 unaccelerated)
                  event4   GESTURE_SWIPE_UPDATE      2 +19.417s  3 21.24/ 0.00 ( 4.61/ 0.00 unaccelerated)
                  event4   GESTURE_SWIPE_UPDATE      3 +19.424s  3  6.36/-0.22 ( 6.36/-0.22 unaccelerated)
                  event4   GESTURE_SWIPE_END           +19.614s  3
                EVENTS
                  .split("\n")
              end

              let(:event) {
                -> {
                  record = @debug_events.shift
                  Events::Event.new(tag: "libinput_command_input", record: record)
                }
              }

              it "has a gesture record" do
                expect(parser.parse(event.call).record).to be_a Events::Records::GestureRecord
              end

              it "has a gesture record that it has a status" do
                expect(parser.parse(event.call).record.status).to eq "begin"
                expect(parser.parse(event.call).record.status).to eq "update"
                expect(parser.parse(event.call).record.status).to eq "update"
                expect(parser.parse(event.call).record.status).to eq "update"
                expect(parser.parse(event.call).record.status).to eq "end"
              end

              it "has a gesture record that it has finger num" do
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
              end
            end
          end

          context "with libinput version 1.26.0 or earlier" do
            before do
              allow_any_instance_of(LibinputCommand).to receive(:libinput_1_27_0_or_later?).and_return(false)
            end

            context "with swipe gestures" do
              before do
                @debug_events = <<~EVENTS
                  event10  GESTURE_SWIPE_BEGIN     +0.728s       3
                  event10  GESTURE_SWIPE_UPDATE    +0.948s       3  0.23/ 0.00 ( 0.29/ 0.00 unaccelerated)
                  event10  GESTURE_SWIPE_END       +0.989s       3
                EVENTS
                  .split("\n")
              end

              let(:event) {
                -> {
                  record = @debug_events.shift
                  Events::Event.new(tag: "libinput_command_input", record: record)
                }
              }

              it "has a gesture record" do
                expect(parser.parse(event.call).record).to be_a Events::Records::GestureRecord
              end

              it "has a gesture record that it has a status" do
                expect(parser.parse(event.call).record.status).to eq "begin"
                expect(parser.parse(event.call).record.status).to eq "update"
                expect(parser.parse(event.call).record.status).to eq "end"
              end

              it "has a gesture record that it has finger num" do
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
              end
            end

            context "with hold gestures" do
              before do
                @debug_events = <<~EVENTS
                -event10  GESTURE_HOLD_BEGIN      +2.125s       3
                event10  GESTURE_HOLD_END        +3.274s       3
                event10  GESTURE_HOLD_BEGIN      +5.573s       4
                event10  GESTURE_HOLD_END        +6.462s       4 cancelled
                EVENTS
                  .split("\n")
              end

              let(:event) {
                -> {
                  record = @debug_events.shift
                  Events::Event.new(tag: "libinput_command_input", record: record)
                }
              }

              it "has a gesture record" do
                expect(parser.parse(event.call).record).to be_a Events::Records::GestureRecord
              end

              it "has a gesture record that it has a status" do
                expect(parser.parse(event.call).record.status).to eq "begin"
                expect(parser.parse(event.call).record.status).to eq "end"
                expect(parser.parse(event.call).record.status).to eq "begin"
                expect(parser.parse(event.call).record.status).to eq "cancelled"
              end

              it "has a gesture record that it has finger num" do
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 3
                expect(parser.parse(event.call).record.finger).to eq 4
                expect(parser.parse(event.call).record.finger).to eq 4
              end
            end
          end
        end
      end
    end
  end
end
