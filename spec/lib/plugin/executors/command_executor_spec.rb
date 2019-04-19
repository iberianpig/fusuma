require 'spec_helper'

module Fusuma
  module Plugin
    module Executors
      COMMAND_OPTIONS = { executors: { command_executor: 'command' } }.freeze

      RSpec.describe CommandExecutor do
        let(:command_executor) { described_class.new(options) }
        let(:options) { {} }

        describe '#execute' do
          subject { command_executor.execute(command_event) }
          let(:command_event) { Formats::Event.new(tag: 'command', record: 'command') }
          it { expect { subject }.to output("command\n").to_stdout }
        end

        describe '#executable?' do
          subject { command_executor.executable?(command_event) }

          context 'event source is matched with tag' do
            let(:command_event) { Formats::Event.new(tag: 'command', record: 'command') }
            it { is_expected.to be true }
          end

          context 'event source is NOT matched with tag' do
            let(:command_event) { Formats::Event.new(tag: 'INVALID_TAG', record: 'command') }
            it { is_expected.to be false }
          end
        end

        describe '#source' do
          subject { command_executor.source }

          it { is_expected.to be CommandExecutor::DEFAULT_SOURCE }

          context 'with source option' do
            let(:options) { { source: 'awesome_source' } }
            it { is_expected.to eq 'awesome_source' }
          end
        end
      end
    end
  end
end
