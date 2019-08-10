# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/executors/command_executor.rb'
require './lib/fusuma/plugin/events/event.rb'

module Fusuma
  module Plugin
    module Executors
      RSpec.describe CommandExecutor do
        before do
          record = Events::Records::VectorRecord.new(gesture: 'dummy',
                                                     finger: 1,
                                                     direction: 'dummy_direction',
                                                     quantity: 0)
          @event = Events::Event.new(tag: 'dummy_detector', record: record)
          @executor = CommandExecutor.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              1:
                dummy_direction:
                  command: 'echo dummy'
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#execute' do
          it 'fork' do
            allow(Process).to receive(:daemon).with(true)
            allow(Process).to receive(:detach).with(anything)
            expect(@executor).to receive(:fork).and_yield do |block_context|
              expect(block_context).to receive(:exec).with(anything)
            end

            @executor.execute(@event)
          end
        end

        describe '#executable?' do
          context 'detector is matched with config file' do
            it { expect(@executor.executable?(@event)).to be_truthy }
          end

          context 'detector is NOT matched with config file' do
            before do
              @event.tag = 'invalid'
            end
            it { expect(@executor.executable?(@event)).to be_falsey }
          end
        end
      end
    end
  end
end
