# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/executors/command_executor.rb'
require_relative './dummy_vector.rb'

module Fusuma
  module Plugin
    module Executors
      RSpec.describe CommandExecutor do
        let(:command_executor) { described_class.new }
        let(:vector) { Vectors::DummyVector.new('dummy_finger', 'dummy_direction') }

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              dummy_finger:
                dummy_direction:
                  command: 'echo dummy'
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#execute' do
          subject { command_executor.execute(vector) }

          it 'fork' do
            allow(Process).to receive(:daemon).with(true)
            allow(Process).to receive(:detach).with(anything)
            expect(command_executor).to receive(:fork).and_yield do |block_context|
              expect(block_context).to receive(:exec).with(anything)
            end

            subject
          end
        end

        describe '#executable?' do
          subject { command_executor.executable?(vector) }

          context 'vector is matched with config file' do
            it { is_expected.to be_truthy }
          end

          context 'vector is matched with config file' do
            let(:vector) do
              Vectors::DummyVector.new('invalid_finger', 'invalid_direction')
            end
            it { is_expected.to be_falsey }
          end
        end
      end
    end
  end
end
