# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/detectors/hold_detector"
require "./lib/fusuma/plugin/buffers/gesture_buffer"
require "./lib/fusuma/plugin/events/records/gesture_record"
require "./lib/fusuma/config"
require "./lib/fusuma/plugin/inputs/timer_input"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe HoldDetector do
        before do
          @detector = HoldDetector.new
          @buffer = Buffers::GestureBuffer.new
          @timer_buffer = Buffers::TimerBuffer.new
          @timer = Inputs::TimerInput.instance
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            threshold:
              hold: 1
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe "#detect" do
          context "with no hold event in buffer" do
            before do
              @buffer.clear
            end
            it { expect(@detector.detect([@buffer, @timer_buffer])).to eq nil }
          end

          context "with only hold begin event" do
            before do
              events = create_hold_events(statuses: ["begin"])
              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer, @timer_buffer])).to be_a Events::Event }
            it { expect(@detector.detect([@buffer, @timer_buffer]).record).to be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer, @timer_buffer]).record.index).to be_a Config::Index }
            it "should detect 3 fingers hold" do
              event = @detector.detect([@buffer, @timer_buffer])
              expect(event.record.index.keys.map(&:symbol)).to eq([:hold, 3, :begin])
            end
          end

          context "with hold events(begin,cancelled)" do
            before do
              events = create_hold_events(statuses: %w[begin cancelled])
              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer, @timer_buffer])).to be_a Events::Event }
            it { expect(@detector.detect([@buffer, @timer_buffer]).record).to be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer, @timer_buffer]).record.index).to be_a Config::Index }
            it "should detect 3 fingers hold canclled" do
              event = @detector.detect([@buffer, @timer_buffer])
              expect(event.record.index.keys.map(&:symbol)).to eq([:hold, 3, :cancelled])
            end
          end

          context "with hold events(begin,end)" do
            before do
              events = create_hold_events(statuses: %w[begin end])
              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer, @timer_buffer])).to be_a Events::Event }
            it { expect(@detector.detect([@buffer, @timer_buffer]).record).to be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer, @timer_buffer]).record.index).to be_a Config::Index }
            it "should detect 3 fingers hold" do
              events = @detector.detect([@buffer, @timer_buffer])
              expect(events.record.index.keys.map(&:symbol)).to eq([:hold, 3, :end])
            end
          end

          context "with hold events and timer events" do
            context "with begin event and timer events" do
              before do
                events = create_hold_events(statuses: %w[begin])
                events.each { |event| @buffer.buffer(event) }
                @time = events.last.time
                @timer_buffer.buffer(create_timer_event(time: @time + HoldDetector::BASE_THERESHOLD))
              end
              it { expect(@detector.detect([@buffer, @timer_buffer])).to eq nil }

              context "with enough holding time" do
                before do
                  @timer_buffer.clear
                  @timer_buffer.buffer(create_timer_event(time: @time + HoldDetector::BASE_THERESHOLD + 0.01))
                end
                it { expect(@detector.detect([@buffer, @timer_buffer])).to be_a Events::Event }
                it { expect(@detector.detect([@buffer, @timer_buffer]).record).to be_a Events::Records::IndexRecord }
                it { expect(@detector.detect([@buffer, @timer_buffer]).record.index).to be_a Config::Index }
                it "should detect 3 fingers hold" do
                  events = @detector.detect([@buffer, @timer_buffer])
                  expect(events.record.index.keys.map(&:symbol)).to eq([:hold, 3])
                end
              end
              context "with changing threshold" do
                around do |example|
                  ConfigHelper.load_config_yml = <<~CONFIG
                    threshold:
                      hold: 0.9
                  CONFIG

                  example.run

                  Config.custom_path = nil
                end

                it { expect(@detector.detect([@buffer, @timer_buffer])).not_to eq nil }
                it "should detect 3 fingers hold" do
                  events = @detector.detect([@buffer, @timer_buffer])
                  expect(events.record.index.keys.map(&:symbol)).to eq([:hold, 3])
                end
              end
            end
          end
        end

        private

        def create_hold_events(statuses:)
          record_type = HoldDetector::GESTURE_RECORD_TYPE
          statuses.map do |status|
            gesture_record = Events::Records::GestureRecord.new(status: status,
              gesture: record_type,
              finger: 3,
              delta: nil)
            Events::Event.new(tag: "libinput_gesture_parser", record: gesture_record)
          end
        end

        def create_timer_event(time: Time.now)
          Events::Event.new(time: time, tag: "timer_input", record: Events::Records::TextRecord.new("timer"))
        end
      end
    end
  end
end
