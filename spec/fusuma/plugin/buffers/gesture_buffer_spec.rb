# frozen_string_literal: true

require "spec_helper"
require "rspec-parameterized"

require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/plugin/events/records/gesture_record"
require "./lib/fusuma/plugin/buffers/gesture_buffer"

module Fusuma
  module Plugin
    module Buffers
      RSpec.describe GestureBuffer do
        before do
          @buffer = GestureBuffer.new
          delta = Events::Records::GestureRecord::Delta.new(-1, 0, 0, 0, 0, 0)
          @event_generator = lambda { |time = nil, status = "update"|
            Events::Event.new(time: time,
              tag: "libinput_gesture_parser",
              record: Events::Records::GestureRecord.new(
                status: status,
                gesture: "SWIPE",
                finger: 3,
                delta: delta
              ))
          }
        end

        describe "#type" do
          it { expect(@buffer.type).to eq "gesture" }
        end

        describe "#buffer" do
          it "should buffer gesture event" do
            event = @event_generator.call
            @buffer.buffer(event)
            expect(@buffer.events).to eq [event]
          end

          it "should NOT buffer other event" do
            event = Events::Event.new(tag: "SHOULD NOT BUFFER", record: "dummy record")
            @buffer.buffer(event)
            expect(@buffer.events).to eq []
          end

          it "should buffer begin/end" do
            begin_event = @event_generator.call(nil, "begin")
            @buffer.buffer(begin_event)
            expect(@buffer.events).to eq [begin_event]
            end_event = @event_generator.call(nil, "end")
            @buffer.buffer(end_event)
            expect(@buffer.events).to eq [begin_event, end_event]
          end
        end

        describe "#clear_expired" do
          context "default" do
            before do
              @time = Time.now
              event1 = @event_generator.call(@time)
              @buffer.buffer(event1)
              @event2 = @event_generator.call(@time + 100)
              @event3 = @event_generator.call(@time + 100)
              @buffer.buffer(@event2)
              @buffer.buffer(@event3)
            end
            it "should keep only events generated within 30 seconds" do
              @buffer.clear_expired(current_time: @time + 100.1)
              expect(@buffer.events).to eq [@event2, @event3]
            end
            context "with cancelled or ended" do
              where(:last_state, :want) do
                [
                  ["end", []],
                  ["cancelled", []]
                ]
              end

              with_them do
                it "should clear events" do
                  event4 = @event_generator.call(@time + 100, last_state)
                  @buffer.buffer(event4)

                  @buffer.clear_expired(current_time: @time + 100.1)
                  expect(@buffer.events).to eq want
                end
              end
            end
          end
          context "change seconds to keep" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  buffers:
                    gesture_buffer:
                      seconds_to_keep: 0.3
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "should keep only events generated within 0.3 seconds" do
              expect(@buffer.config_params(:seconds_to_keep)).to eq(0.3)
              time = Time.now
              event1 = @event_generator.call(time)
              @buffer.buffer(event1)
              event2 = @event_generator.call(time + 0.1)
              @buffer.buffer(event2)
              event3 = @event_generator.call(time + 0.2)
              @buffer.buffer(event3)
              @buffer.clear_expired(current_time: time + 0.29)
              expect(@buffer.events).to eq [event1, event2, event3]

              @buffer.clear_expired(current_time: time + 0.3)
              expect(@buffer.events).to eq [event2, event3]
            end
          end
        end

        describe "#source" do
          it { expect(@buffer.source).to eq GestureBuffer::DEFAULT_SOURCE }

          context "with config" do
            around do |example|
              @source = "custom_event"

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  buffers:
                    gesture_buffer:
                      source: #{@source}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { expect(@buffer.source).to eq @source }
          end
        end

        describe "#sum_attrs" do
          it "should calculate the sum of each attribute"
        end

        describe "#avg_attrs" do
          it "should calculate the average of each attribute"
        end

        describe "#finger" do
          it "should return number of fingers in gestures"
        end

        describe "#gesture" do
          it "should return string of gesture type"
        end

        describe "#empty?" do
          context "no gestures in buffer" do
            before { @buffer.clear }
            it { expect(@buffer.empty?).to be true }
          end

          context "buffered some gestures" do
            before { @buffer.buffer(@event_generator.call) }
            it { expect(@buffer.empty?).to be false }
          end
        end
      end
    end
  end
end
