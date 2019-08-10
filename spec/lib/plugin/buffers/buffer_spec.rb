# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/plugin/events/event.rb'
require_relative './dummy_buffer.rb'

module Fusuma
  module Plugin
    module Buffers
      RSpec.describe DummyBuffer do
        before do
          @buffer = DummyBuffer.new
        end

        describe '#type' do
          subject { @buffer.type }
          it { is_expected.to eq 'dummy' }
        end

        describe '#buffer' do
          it 'should buffer event' do
            event = Events::Event.new(tag: 'dummy', record: 'dummy record')
            expect(@buffer.buffer(event)).to eq [event]
            expect(@buffer.events).to eq [event]
          end

          it 'should NOT buffer event' do
            event = Events::Event.new(tag: 'SHOULD NOT BUFFER', record: 'dummy record')
            @buffer.buffer(event)
            expect(@buffer.events).to eq []
          end
        end

        describe '#source' do
          subject { @buffer.source }

          it { is_expected.to eq DummyBuffer::DEFAULT_SOURCE }

          context 'with config' do
            around do |example|
              CUSTOME_SOURCE = 'custom_event'

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 buffers:
                   dummy_buffer:
                     source: #{CUSTOME_SOURCE}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { is_expected.to eq CUSTOME_SOURCE }
          end
        end

        describe '#config_params' do
          around do |example|
            ConfigHelper.load_config_yml = <<~CONFIG
              plugin:
               buffers:
                 dummy_buffer:
                   dummy: dummy
            CONFIG

            example.run

            Config.custom_path = nil
          end

          subject { @buffer.config_params }
          it { is_expected.to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
