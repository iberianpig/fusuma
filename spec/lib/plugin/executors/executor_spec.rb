# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/config.rb'
require './lib/fusuma/plugin/executors/executor.rb'
require './lib/fusuma/plugin/events/event.rb'

module Fusuma
  module Plugin
    module Executors
      RSpec.describe Executor do
        before { @executor = Executor.new }

        describe '#execute' do
          it do
            expect { @executor.execute('dummy') }.to raise_error(NotImplementedError)
          end
        end

        describe '#executable?' do
          it do
            expect { @executor.executable?('dummy') }.to raise_error(NotImplementedError)
          end
        end
      end

      class DummyExecutor < Executor
        def execute(event)
          # stdout
          puts event.record.index.keys.last.symbol if executable?(event)
        end

        def executable?(event)
          event.tag == 'dummy'
        end
      end

      RSpec.describe DummyExecutor do
        before do
          index = Config::Index.new(:dummy_text)
          record = Events::Records::IndexRecord.new(index: index)
          @event = Events::Event.new(tag: 'dummy', record: record)
          @executor = DummyExecutor.new
        end

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
          it { expect { @executor.execute(@event) }.to output("dummy_text\n").to_stdout }

          context 'without executable' do
            before do
              allow(@executor).to receive(:executable?).and_return false
            end
            it { expect { @executor.execute(@event) }.not_to output("dummy_text\n").to_stdout }
          end
        end

        describe '#executable?' do
          it { expect(@executor.executable?(@event)).to be_truthy }
        end

        describe '#config_params' do
          it { expect(@executor.config_params).to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
