# frozen_string_literal: true

require 'spec_helper'
require_relative './dummy_vector.rb'
require './lib/fusuma/plugin/executors/command_executor.rb'
require './lib/fusuma/config.rb'

module Fusuma
  module Plugin
    module Executors
      COMMAND_OPTIONS = { executors: { command_executor: { dummy: 'dummy_options' } } }.freeze

      RSpec.describe CommandExecutor do
        let(:command_executor) { described_class.new(options: options) }
        let(:vector) { Vectors::DummyVector.new('dummy_finger', 'dummy_direction') }
        let(:options) { COMMAND_OPTIONS[:executors][:command_executor] }

        before do
          allow(YAML).to receive(:load_file) {
                           {
                             dummy: {
                               dummy_finger: {
                                 dummy_direction: {
                                   command: 'echo dummy'
                                 }
                               }
                             }
                           }
                         }
          Config.instance.reload
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
