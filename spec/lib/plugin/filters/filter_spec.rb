# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

require './lib/fusuma/config.rb'
require './lib/fusuma/plugin/filters/filter.rb'
require './lib/fusuma/plugin/formats/event_format.rb'

module Fusuma
  module Plugin
    module Filters
      class DummyFilter < Filter
        DEFAULT_SOURCE = 'dummy_input'
      end

      RSpec.describe DummyFilter do
        let(:filter) { DummyFilter.new }

        describe '#source' do
          subject { filter.source }

          it { is_expected.to eq DummyFilter::DEFAULT_SOURCE }

          context 'with config' do
            around do |example|
              CUSTOME_SOURCE = 'custom_input'

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 filters:
                   dummy_filter:
                     source: #{CUSTOME_SOURCE}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { is_expected.to eq CUSTOME_SOURCE }
          end
        end

        describe '#filter' do
          subject { filter.filter(event) }
          let(:event) { Formats::Event.new(tag: 'dummy_input', record: 'dummy') }

          context 'when filter#keep? return false' do
            before do
              allow(filter).to receive(:keep?).and_return(false)
            end

            it { is_expected.to be nil }
          end

          context 'when filter#keep? return true' do
            before do
              allow(filter).to receive(:keep?).and_return(true)
            end

            it { is_expected.to be event }
          end
        end

        describe '#config_params' do
          around do |example|
            ConfigHelper.load_config_yml = <<~CONFIG
              plugin:
               filters:
                 dummy_filter:
                   dummy: dummy
            CONFIG

            example.run

            Config.custom_path = nil
          end

          subject { filter.config_params }
          it { is_expected.to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
