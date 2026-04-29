# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/detectors/watch_context_detector"
require "./lib/fusuma/plugin/buffers/watch_context_buffer"
require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/plugin/events/records/text_record"
require "./lib/fusuma/plugin/events/records/context_record"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe WatchContextDetector do
        before do
          @detector = WatchContextDetector.new
          @buffer = Buffers::WatchContextBuffer.new
        end

        describe "class" do
          it "inherits from Detector" do
            expect(WatchContextDetector.superclass).to eq Detector
          end
        end

        describe "#sources" do
          it "returns ['watch_context']" do
            expect(@detector.sources).to eq ["watch_context"]
          end
        end

        describe "#watch?" do
          it "returns true" do
            expect(@detector.watch?).to be true
          end
        end

        describe "#detect" do
          context "with empty buffer" do
            before do
              @buffer.clear
            end

            it "returns nil" do
              expect(@detector.detect([@buffer])).to be_nil
            end
          end

          context "with events in buffer" do
            before do
              @buffer.clear
              event = Events::Event.new(
                tag: "watch_context_input",
                record: Events::Records::TextRecord.new("window:Firefox")
              )
              @buffer.buffer(event)
            end

            it "returns an Event" do
              result = @detector.detect([@buffer])
              expect(result).to be_a Events::Event
            end

            it "returns Event with ContextRecord" do
              result = @detector.detect([@buffer])
              expect(result.record).to be_a Events::Records::ContextRecord
            end

            it "parses name and value correctly" do
              result = @detector.detect([@buffer])
              expect(result.record.name).to eq :window
              expect(result.record.value).to eq "Firefox"
            end

            it "clears the buffer after detection" do
              @detector.detect([@buffer])
              expect(@buffer.events).to be_empty
            end
          end

          context "with value containing colons" do
            before do
              @buffer.clear
              event = Events::Event.new(
                tag: "watch_context_input",
                record: Events::Records::TextRecord.new("time:12:30:45")
              )
              @buffer.buffer(event)
            end

            it "parses correctly by splitting on first colon only" do
              result = @detector.detect([@buffer])
              expect(result.record.name).to eq :time
              expect(result.record.value).to eq "12:30:45"
            end
          end
        end
      end
    end
  end
end
