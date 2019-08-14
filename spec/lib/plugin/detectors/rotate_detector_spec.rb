# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/detectors/rotate_detector.rb'
require './lib/fusuma/plugin/buffers/gesture_buffer.rb'
require './lib/fusuma/plugin/events/event.rb'
require './lib/fusuma/config.rb'

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

          Config.custom_path = nil
        end

        describe '#detect' do
          context 'with no rotate event in buffer' do
            before do
              @buffer.clear
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context 'with not enough rotate events in buffer' do
            before do
              directions = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0.4),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0.5)
              ]
              events = create_events(directions: directions)

              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer])).to eq nil }
          end

          context 'with enough rotate in event' do
            before do
              directions = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0.5),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, 0.6)
              ]
              events = create_events(directions: directions)

              events.each { |event| @buffer.buffer(event) }
            end
            it {
              expect(@detector.detect([@buffer])).to be_a Events::Event
            }
            it { expect(@detector.detect([@buffer]).record).to be_a Events::Records::VectorRecord }
            it { expect(@detector.detect([@buffer]).record.index).to be_a Config::Index }
            it { expect(@detector.detect([@buffer]).record.direction).to eq 'clockwise' }
          end

          context 'with enough rotate out event' do
            before do
              directions = [
                Events::Records::GestureRecord::Delta.new(0, 0, 0, -0.5),
                Events::Records::GestureRecord::Delta.new(0, 0, 0, -0.6)
              ]
              events = create_events(directions: directions)

              events.each { |event| @buffer.buffer(event) }
            end
            it { expect(@detector.detect([@buffer]).record.direction).to eq 'counterclockwise' }
          end
        end

        def create_events(directions: [])
          record_type = RotateDetector::GESTURE_RECORD_TYPE
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
