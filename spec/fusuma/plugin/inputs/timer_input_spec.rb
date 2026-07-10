# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/inputs/timer_input"

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe TimerInput do
        before do
          @dummy_read = StringIO.new("dummy_read")
          @dummy_write = StringIO.new("dummy_write")
          @input = TimerInput.instance
          allow(@input).to receive(:create_io).and_return [@dummy_read, @dummy_write]
          allow(Thread).to receive(:new)
        end

        describe "#io" do
          it "should call #create_io" do
            expect(@input).to receive(:create_io)
            expect(@input).to receive(:start)
            expect(@input.io).to eq @dummy_read
          end
        end

        describe "#start" do
          it {
            expect(Thread).to receive(:new).and_yield do |block_context|
              expect(block_context).to receive(:timer_loop).with(@dummy_write)
            end
            @input.start(@dummy_read, @dummy_write)
          }
        end

        describe "#config_params" do
          context "with Integer interval in config.yml" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    timer_input:
                      interval: 3
              CONFIG

              # TimerInput is a Singleton and memoizes @config_params,
              # so reset the cache before and after this example
              TimerInput.instance.instance_variable_set(:@config_params, {})

              example.run

              TimerInput.instance.instance_variable_set(:@config_params, {})
              ConfigHelper.clear_config_yml
            end

            it "does not exit and returns the Integer value" do
              expect(@input.config_params(:interval)).to eq 3
            end
          end
        end
      end
    end
  end
end
