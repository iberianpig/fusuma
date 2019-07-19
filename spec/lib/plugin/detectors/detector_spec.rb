# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/detectors/detector.rb'
require './lib/fusuma/config.rb'

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe Detector do
        let(:detector) { described_class.new }

        describe '#execute' do
          subject { detector.execute('dummy') }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end

        describe '#executable?' do
          subject { detector.executable?('dummy') }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end
      end

      class DummyDetector < Detector
        def execute(vector)
          puts vector.direction
        end

        def executable?(vector)
          vector.to_s
        end
      end

      RSpec.describe DummyDetector do
        let(:dummy_detector) { described_class.new }
        let(:vector) { Vectors::DummyVector.new('dummy_finger', 'dummy_direction') }

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

        describe '#execute' do
          subject { dummy_detector.execute(vector) }
          it { expect { subject }.to output("dummy_direction\n").to_stdout }
        end

        describe '#executable?' do
          subject { dummy_detector.executable?(vector) }
          it { is_expected.to be_truthy }
        end

        describe '#config_params' do
          subject { dummy_detector.config_params }
          it { is_expected.to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
