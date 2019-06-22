# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/inputs/input.rb'

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe Input do
        let(:input) { described_class.new }

        describe '#run' do
          subject { input.run { 'dummy' } }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end

        describe '#event' do
          subject { input.event }
          it { is_expected.to be_a Formats::Event }

          it { expect(input.tag).to eq 'input' }
        end
      end

      DUMMY_OPTIONS = { plugin: { inputs: { dummy_input: 'dummy' } } }.freeze

      class DummyInput < Input
        def run
          yield event
        end
      end

      RSpec.describe DummyInput do
        let(:dummy_input) { described_class.new }

        before do
          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
             inputs:
               dummy_input:
                 dummy: dummy
          CONFIG
        end

        describe '#run' do
          subject { dummy_input.run { |e| return e } }
          it { is_expected.to be_a Formats::Event }
        end

        describe '#config_params' do
          subject { dummy_input.config_params }
          it { is_expected.to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
