# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/inputs/input.rb'

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe Input do
        let(:input) { described_class.new }

        describe '#io' do
          subject { input.io { 'dummy' } }
          it { expect { subject }.to raise_error(NotImplementedError) }
        end

        describe '#create_event' do
          subject { input.create_event }
          it { is_expected.to be_a Events::Event }

          it { expect(input.tag).to eq 'input' }
        end

        describe '.select' do
          subject { Input.select([DummyInput.new]) }

          it { is_expected.to be_a Events::Event }
        end
      end

      class DummyInput < Input
        def io
          @io ||= begin
                    r, w = IO.pipe
                    w.puts 'hoge'
                    w.close
                    r
                  end
        end
      end

      RSpec.describe DummyInput do
        let(:dummy_input) { described_class.new }

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
             inputs:
               dummy_input:
                 dummy: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#io' do
          subject { dummy_input.io }
          it { is_expected.to be_a IO }
        end

        describe '#config_params' do
          subject { dummy_input.config_params }
          it { is_expected.to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
