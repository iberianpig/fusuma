# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/detectors/rotate_detector"
require "./lib/fusuma/plugin/buffers/gesture_buffer"
require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/config"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe RotateDetector do
        before do
          @detector = RotateDetector.new
          @buffer = Buffers::GestureBuffer.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            threshold:
              rotate: 1
          CONFIG

          example.run

          ConfigHelper.clear_config_yml
        end

        describe "#detect" do
          context "with no rotate event in buffer" do
            before do
              @buffer.clear
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context "with not enough rotate events in buffer" do
            before do
              deltas = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, 0.4),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, 0.5)
              ]
              events = create_events(deltas: deltas)

              events.each { |event| @buffer.buffer(event) }
            end
            it "should have repeat record" do
              expect(@detector.detect([@buffer]).record.trigger).to eq :repeat
            end
          end

          context "with enough rotate IN event" do
            before do
              deltas = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, 0.5),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, 0.6),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, 0.6)
              ]
              events = create_events(deltas: deltas)

              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to all be_a Events::Event }
            it {
              expect(@detector.detect([@buffer]).map(&:record)).to all be_a Events::Records::IndexRecord
            }
            it {
              expect(@detector.detect([@buffer]).map(&:record).map(&:index)).to all be_a Config::Index
            }
            it "should detect 3 fingers rotate-clockwise (oneshot/repeat)" do
              events = @detector.detect([@buffer])
              expect(events[0].record.index.keys.map(&:symbol))
                .to eq([:rotate, 3, :clockwise])
              expect(events[1].record.index.keys.map(&:symbol))
                .to eq([:rotate, 3, :clockwise, :update])
            end
          end

          context "with enough rotate OUT event" do
            before do
              deltas = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, -0.5),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, -0.6),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0, -0.6)
              ]
              events = create_events(deltas: deltas)

              events.each { |event| @buffer.buffer(event) }
            end
            it "should detect 3 fingers rotate-counterclockwise" do
              events = @detector.detect([@buffer])
              indexes = events.map { |e| e.record.index.keys.map(&:symbol) }
              expect(indexes).to eq(
                [
                  [:rotate, 3, :counterclockwise],
                  [:rotate, 3, :counterclockwise, :update]
                ]
              )
            end
          end
        end

        private

        def create_events(deltas: [])
          record_type = RotateDetector::GESTURE_RECORD_TYPE
          deltas.map do |delta|
            status = if deltas[0].equal? delta
              "begin"
            else
              "update"
            end

            gesture_record = Events::Records::GestureRecord.new(status: status,
              gesture: record_type,
              finger: 3,
              delta: delta)
            Events::Event.new(tag: "libinput_gesture_parser", record: gesture_record)
          end
        end
      end
    end
  end
end
