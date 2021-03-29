# frozen_string_literal: true

require 'spec_helper'

require './lib/fusuma/config'
require './lib/fusuma/plugin/executors/executor'
require './lib/fusuma/plugin/detectors/detector'
require './lib/fusuma/plugin/events/event'

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
          index = Config::Index.new([*event.record.index.keys, :dummy])
          content = Config.search(index)

          # stdout
          puts content if executable?(event)
        end

        def executable?(event)
          event.tag == 'dummy'
        end
      end

      RSpec.describe DummyExecutor do
        before do
          index = Config::Index.new([:dummy_gesture,
                                     Config::Index::Key.new(:dummy_direction, skippable: true)])
          record = Events::Records::IndexRecord.new(index: index)
          @event = Events::Event.new(tag: 'dummy', record: record)
          @executor = DummyExecutor.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy_gesture:
              dummy_direction:
                dummy: 'echo dummy'
                interval: 0.3

            plugin:
             executors:
               dummy_executor:
                 dummy: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#execute' do
          it { expect { @executor.execute(@event) }.to output("echo dummy\n").to_stdout }
          context 'without executable' do
            before do
              allow(@executor).to receive(:executable?).and_return false
            end
            it { expect { @executor.execute(@event) }.not_to output("echo dummy\n").to_stdout }
          end
        end

        describe '#executable?' do
          it { expect(@executor.executable?(@event)).to be_truthy }
        end

        describe 'interval' do
          it 'should return interval from Config' do
            interval_time = 0.3 * DummyExecutor::BASE_ONESHOT_INTERVAL
            expect(@executor.interval(@event)).to eq interval_time
          end

          context 'without skippable direction' do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                dummy_gesture:
                  interval: 0.1
                  dummy_direction:
                    dummy: 'echo dummy'

                plugin:
                 executors:
                   dummy_executor:
                     dummy: dummy
              CONFIG

              example.run

              Config.custom_path = nil
            end
            it 'should not return parent interval' do
              expect(@executor.interval(@event)).to eq DummyExecutor::BASE_ONESHOT_INTERVAL
              expect(@executor.interval(@event)).not_to eq 0.1 * DummyExecutor::BASE_ONESHOT_INTERVAL
            end

            context 'with Config::Searcher.skip' do
              it 'should return parent interval' do
                Config::Searcher.skip do
                  expect(@executor.interval(@event)).to eq 0.1 * DummyExecutor::BASE_ONESHOT_INTERVAL
                end
              end
            end
          end
        end

        describe 'enough_interval?' do
          it 'should return true at first time' do
            expect(@executor.enough_interval?(@event)).to eq true
          end

          context 'after update_interval' do
            before do
              @executor.update_interval(@event)
            end
            it 'should return false' do
              expect(@executor.enough_interval?(@event)).to eq false
            end

            context 'after wait interval time' do
              before do
                # dummy_gesture/dummy_direction/interval => 0.3
                interval_time = 0.3 * DummyExecutor::BASE_ONESHOT_INTERVAL

                @event2 = Events::Event.new(
                  time: @event.time + interval_time,
                  tag: 'dummy',
                  record: @event.record
                )
              end
              it 'should return true after wait' do
                expect(@executor.enough_interval?(@event2)).to eq true
              end
            end
          end
        end

        describe '#config_params' do
          it { expect(@executor.config_params).to eq(dummy: 'dummy') }
        end
      end
    end
  end
end
