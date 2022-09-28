# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/plugin/events/event"
require "./lib/fusuma/plugin/detectors/detector"
require "./lib/fusuma/config"
require_relative "../buffers/dummy_buffer"
require_relative "./dummy_detector"

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

          ConfigHelper.clear_config_yml
        end

        describe "#detect" do
          it { expect(@detector.detect([@buffer])).to be_a(Events::Event) }
        end

        describe "#config_params" do
          it { expect(@detector.config_params).to eq(dummy: "dummy") }
        end
      end
    end
  end
end
