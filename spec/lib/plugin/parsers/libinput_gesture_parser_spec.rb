# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/parsers/parser"
require "./lib/fusuma/plugin/events/event"

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

          context "with libinput_command_input event" do
            let(:event) { Events::Event.new(tag: "libinput_command_input", record: record) }
            context "with swipe gestures" do
              # event10  GESTURE_SWIPE_BEGIN     +0.728s       3
              # event10  GESTURE_SWIPE_UPDATE    +0.948s       3  0.23/ 0.00 ( 0.29/ 0.00 unaccelerated)
              # event10  GESTURE_SWIPE_END       +0.989s       3
              let(:record) { "event10  GESTURE_SWIPE_BEGIN     +0.728s       3" }
              it { expect(parser.parse(event).record).to be_a Events::Records::GestureRecord }
              it { expect(parser.parse(event).record.status).to eq "begin" }
            end

            context "with hold gestures" do
              # -event10  GESTURE_HOLD_BEGIN      +2.125s       3
              # event10  GESTURE_HOLD_END        +3.274s       3
              # event10  GESTURE_HOLD_BEGIN      +5.573s       4
              # event10  GESTURE_HOLD_END        +6.462s       4 cancelled
              context "with begin" do
                let(:record) { "-event10  GESTURE_HOLD_BEGIN      +2.125s       3" }
                it { expect(parser.parse(event).record).to be_a Events::Records::GestureRecord }
                it { expect(parser.parse(event).record.status).to eq "begin" }
              end
              context "with end" do
                let(:record) { " event10  GESTURE_HOLD_END        +3.274s       3" }
                it { expect(parser.parse(event).record).to be_a Events::Records::GestureRecord }
                it { expect(parser.parse(event).record.status).to eq "end" }
              end
              context "with end(cancelled)" do
                let(:record) { " event10  GESTURE_HOLD_END        +6.462s       4 cancelled" }
                it { expect(parser.parse(event).record).to be_a Events::Records::GestureRecord }
                it { expect(parser.parse(event).record.status).to eq "cancelled" }
              end
            end
          end
        end
      end
    end
  end
end
