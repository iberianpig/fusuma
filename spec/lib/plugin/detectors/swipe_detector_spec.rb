# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/detectors/swipe_detector.rb'
require './lib/fusuma/plugin/buffers/gesture_buffer.rb'
require './lib/fusuma/plugin/events/records/gesture_record.rb'
require './lib/fusuma/config.rb'

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe SwipeDetector do
        before do
          @detector = SwipeDetector.new
          @buffer = Buffers::GestureBuffer.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            threshold:
              swipe: 1
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#detect' do
          context 'with no swipe event in buffer' do
            before do
              @buffer.clear
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context 'with not enough swipe events in buffer' do
            before do
              directions = [
                Events::Records::GestureRecord::Delta.new(0,  0, 0, 0),
                Events::Records::GestureRecord::Delta.new(20, 0, 0, 0)
              ]
              events = create_events(directions: directions)

              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context 'with enough swipe RIGHT event' do
            before do
              directions = [
                Events::Records::GestureRecord::Delta.new(0,  0, 0, 0),
                Events::Records::GestureRecord::Delta.new(21, 0, 0)
              ]
              events = create_events(directions: directions)

              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to be_a Events::Event }
            it { expect(@detector.detect([@buffer]).record).to be_a Events::Records::IndexRecord }
            it { expect(@detector.detect([@buffer]).record.index).to be_a Config::Index }
            it 'should detect 3 fingers swipe-right' do
              expect(@detector.detect([@buffer]).record.index.keys.map(&:symbol))
                .to eq([:swipe, 3, :right])
            end
          end

          context 'with enough swipe DOWN event' do
            before do
              directions = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0),
                Events::Records::GestureRecord::Delta.new(0, 21, 0)
              ]
              events = create_events(directions: directions)

              events.each { |event| @buffer.buffer(event) }
            end
            it 'should detect 3 fingers swipe-down' do
              expect(@detector.detect([@buffer]).record.index.keys.map(&:symbol))
                .to eq([:swipe, 3, :down])
            end
          end
        end

        private

        def create_events(directions: [])
          record_type = SwipeDetector::GESTURE_RECORD_TYPE
          directions.map do |direction|
            gesture_record = Events::Records::GestureRecord.new(status: 'update',
                                                                gesture: record_type,
                                                                finger: 3,
                                                                direction: direction)
            Events::Event.new(tag: 'libinput_gesture_parser', record: gesture_record)
          end
        end
      end
    end
  end
end
