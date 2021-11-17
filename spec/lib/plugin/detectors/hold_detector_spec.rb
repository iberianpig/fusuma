# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/detectors/hold_detector'
require './lib/fusuma/plugin/buffers/gesture_buffer'
require './lib/fusuma/plugin/events/records/gesture_record'
require './lib/fusuma/config'

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe HoldDetector do
        before do
          @detector = HoldDetector.new
          @buffer = Buffers::GestureBuffer.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            threshold:
              hold: 1
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#detect' do
          context 'with no hold event in buffer' do
            before do
              @buffer.clear
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context 'with only hold begin event' do
            before do
              events = create_events(statuses: ['begin'])
              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to be_a Events::Event }
            it { expect(@detector.detect([@buffer]).record).to be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer]).record.index).to be_a Config::Index }
            it 'should detect 3 fingers hold-right' do
              event = @detector.detect([@buffer])
              expect(event.record.index.keys.map(&:symbol))
                .to eq([:hold, 3, :begin])
            end
          end

          context 'with hold events(begin/end)' do
            before do
              events = create_events
              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to all be_a Events::Event }
            it { expect(@detector.detect([@buffer]).map(&:record)).to all be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer]).map(&:record).map(&:index)).to all be_a Config::Index }
            it 'should detect 3 fingers hold-right' do
              events = @detector.detect([@buffer])
              expect(events[0].record.index.keys.map(&:symbol))
                .to eq([:hold, 3])
              expect(events[1].record.index.keys.map(&:symbol))
                .to eq([:hold, 3, :end])
            end
          end
        end

        private

        def create_events(statuses: %w[begin end])
          record_type = HoldDetector::GESTURE_RECORD_TYPE
          statuses.map do |status|
            gesture_record = Events::Records::GestureRecord.new(status: status,
                                                                gesture: record_type,
                                                                finger: 3,
                                                                delta: nil)
            Events::Event.new(tag: 'libinput_gesture_parser', record: gesture_record)
          end
        end
      end
    end
  end
end
