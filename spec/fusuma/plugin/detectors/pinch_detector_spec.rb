# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/detectors/pinch_detector"
require "./lib/fusuma/plugin/buffers/gesture_buffer"
require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/config"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe PinchDetector do
        before do
          @detector = PinchDetector.new
          @buffer = Buffers::GestureBuffer.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            threshold:
              rotate: 1
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe "#detect" do
          context "with no pinch event in buffer" do
            before do
              @buffer.clear
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context "with not enough pinch events in buffer" do
            before do
              deltas = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 1, 0),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 1.1, 0)
              ]
              events = create_events(deltas: deltas)

              events.each { |event| @buffer.buffer(event) }
            end
            it "should have repeat record" do
              expect(@detector.detect([@buffer]).record.trigger).to eq :repeat
            end
          end

          context "with enough pinch OUT event" do
            before do
              deltas = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 1.0, 0),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 1.0, 0),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 2.0, 0)
              ]
              events = create_events(deltas: deltas)

              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to all be_a Events::Event }
            it { expect(@detector.detect([@buffer]).map(&:record)).to all be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer]).map(&:record).map(&:index)).to all be_a Config::Index }

            it "should detect 3 fingers pinch-in (oneshot/repeat)" do
              events = @detector.detect([@buffer])
              expect(events[0].record.index.keys.map(&:symbol))
                .to eq([:pinch, 3, :out])
              expect(events[1].record.index.keys.map(&:symbol))
                .to eq([:pinch, 3, :out, :update])
            end
          end

          context "with enough pinch In event" do
            before do
              deltas = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 1.0, 0),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0.6, 0),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0, 0.3, 0)
              ]
              events = create_events(deltas: deltas)

              events.each { |event| @buffer.buffer(event) }
            end
            it "should detect 3 fingers pinch-in (oneshot/repeat)" do
              events = @detector.detect([@buffer])
              expect(events[0].record.index.keys.map(&:symbol))
                .to eq([:pinch, 3, :in])
              expect(events[1].record.index.keys.map(&:symbol))
                .to eq([:pinch, 3, :in, :update])
            end
          end
        end

        private

        def create_events(deltas: [])
          record_type = PinchDetector::GESTURE_RECORD_TYPE
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
