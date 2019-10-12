# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/events/event.rb'
require './lib/fusuma/plugin/detectors/detector.rb'
require './lib/fusuma/config.rb'
require_relative '../buffers/dummy_buffer.rb'
require_relative './dummy_detector.rb'

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe DummyDetector do
        before do
          @detector = DummyDetector.new
          @buffer = Buffers::DummyBuffer.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
             detectors:
               dummy_detector:
                 dummy: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#detect' do
          it { expect(@detector.detect([@buffer])).to be_a(Events::Event) }
        end

        describe '#config_params' do
          it { expect(@detector.config_params).to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
