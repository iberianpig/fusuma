# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/plugin/buffers/timer_buffer"

module Fusuma
  module Plugin
    module Buffers
      RSpec.describe TimerBuffer do
        before do
          @buffer = TimerBuffer.new
        end

        describe "#type" do
          subject { @buffer.type }
          it { is_expected.to eq "timer" }
        end

        describe "#buffer" do
          it "should buffer event and return self" do
            event = Events::Event.new(tag: "timer_input", record: "timer")
            expect(@buffer.buffer(event)).to eq @buffer
            expect(@buffer.events).to eq [event]
          end

          it "should NOT buffer event with unmatched tag" do
            event = Events::Event.new(tag: "libinput_gesture_parser", record: "timer")
            expect(@buffer.buffer(event)).to be_nil
            expect(@buffer.events).to eq []
          end
        end

        describe "#source" do
          subject { @buffer.source }

          it { is_expected.to eq TimerBuffer::DEFAULT_SOURCE }

          context "with config" do
            around do |example|
              @source = "custom_timer_input"

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 buffers:
                   timer_buffer:
                     source: #{@source}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { is_expected.to eq @source }
          end
        end

        describe "#clear_expired" do
          before do
            @now = Time.now
            @old_event = Events::Event.new(time: @now - 5, tag: "timer_input", record: "timer")
            @new_event = Events::Event.new(time: @now - 1, tag: "timer_input", record: "timer")
            @buffer.buffer(@old_event)
            @buffer.buffer(@new_event)
          end

          it "should clear events older than DEFAULT_SECONDS_TO_KEEP" do
            @buffer.clear_expired(current_time: @now)
            expect(@buffer.events).to eq [@new_event]
          end

          context "with seconds_to_keep configured" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 buffers:
                   timer_buffer:
                     seconds_to_keep: 10
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "should keep events within configured seconds_to_keep" do
              @buffer.clear_expired(current_time: @now)
              expect(@buffer.events).to eq [@old_event, @new_event]
            end
          end
        end
      end
    end
  end
end
