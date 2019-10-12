# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

require './lib/fusuma/config.rb'
require './lib/fusuma/plugin/filters/libinput_device_filter.rb'
require './lib/fusuma/plugin/events/event.rb'

module Fusuma
  module Plugin
    module Filters
      RSpec.describe LibinputDeviceFilter do
        let(:filter) { LibinputDeviceFilter.new }

        describe '#source' do
          it { expect(filter.source).to eq LibinputDeviceFilter::DEFAULT_SOURCE }

          context 'with config' do
            around do |example|
              CUSTOME_SOURCE = 'custom_input'

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 filters:
                   libinput_device_filter:
                     source: #{CUSTOME_SOURCE}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { expect(filter.source).to eq CUSTOME_SOURCE }
          end
        end

        describe '#filter' do
          let(:event) { Events::Event.new(tag: 'libinput_command_input', record: 'dummy') }

          context 'when filter#keep? return false' do
            before do
              allow(filter).to receive(:keep?).and_return(false)
            end

            it { expect(filter.filter(event)).to be nil }
          end

          context 'when filter#keep? return true' do
            before do
              allow(filter).to receive(:keep?).and_return(true)
            end

            it { expect(filter.filter(event)).to be event }
          end
        end

        describe '#keep?' do
          pending 'Not implemented'
        end
      end
    end
  end
end
