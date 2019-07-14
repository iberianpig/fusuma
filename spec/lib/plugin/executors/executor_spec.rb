# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

require './lib/fusuma/config.rb'
require './lib/fusuma/plugin/executors/executor.rb'
require_relative './dummy_vector.rb'

module Fusuma
  module Plugin
    module Executors
      RSpec.describe Executor do
        let(:executor) { described_class.new }

        describe '#execute' do
          subject { executor.execute('dummy') }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end

        describe '#executable?' do
          subject { executor.executable?('dummy') }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end
      end

      class DummyExecutor < Executor
        def execute(vector)
          puts vector.direction
        end

        def executable?(vector)
          vector.to_s
        end
      end

      RSpec.describe DummyExecutor do
        let(:dummy_executor) { described_class.new }
        let(:vector) { Vectors::DummyVector.new('dummy_finger', 'dummy_direction') }

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
             executors:
               dummy_executor:
                 dummy: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#execute' do
          subject { dummy_executor.execute(vector) }
          it { expect { subject }.to output("dummy_direction\n").to_stdout }
        end

        describe '#executable?' do
          subject { dummy_executor.executable?(vector) }
          it { is_expected.to be_truthy }
        end

        describe '#config_params' do
          subject { dummy_executor.config_params }
          it { is_expected.to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
