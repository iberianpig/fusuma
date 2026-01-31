# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/inputs/tail_context_input"

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe TailContextInput do
        before do
          @input = TailContextInput.instance
        end

        describe "class" do
          it "inherits from Input" do
            expect(TailContextInput.superclass).to eq Input
          end

          it "is a Singleton" do
            expect(TailContextInput.included_modules).to include Singleton
          end
        end

        describe "#io" do
          before do
            @dummy_read = StringIO.new("dummy_read")
            @dummy_write = StringIO.new("dummy_write")
            allow(@input).to receive(:create_io).and_return [@dummy_read, @dummy_write]
            allow(Thread).to receive(:new)
          end

          it "returns IO object (reader)" do
            expect(@input.io).to eq @dummy_read
          end
        end

        describe "#execute_command" do
          it "returns stripped output of the command" do
            result = @input.execute_command("echo 'hello world'")
            expect(result).to eq "hello world"
          end

          it "returns nil when command fails" do
            result = @input.execute_command("exit 1")
            expect(result).to be_nil
          end
        end

        describe "#tail_contexts" do
          context "with config" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                tail_context:
                  window:
                    command: "xdotool getactivewindow getwindowname"
                    interval: 0.5
                  time:
                    command: "date +%H:%M"
                    interval: 60
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "returns tail_context settings from config" do
              result = @input.tail_contexts
              expect(result).to be_a Hash
              expect(result.keys).to contain_exactly(:window, :time)
              expect(result[:window][:command]).to eq "xdotool getactivewindow getwindowname"
              expect(result[:window][:interval]).to eq 0.5
            end
          end

          context "without config" do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                swipe:
                  3:
                    left:
                      command: 'echo left'
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it "returns empty hash" do
              result = @input.tail_contexts
              expect(result).to eq({})
            end
          end
        end

        describe "#watch_command" do
          before do
            @writer = StringIO.new
            @input.reset_last_values
          end

          it "writes 'name:value' to writer when value changes" do
            allow(@input).to receive(:execute_command).and_return("Firefox")
            @input.watch_command(name: "window", command: "get_window", writer: @writer)
            @writer.rewind
            expect(@writer.read).to eq "window:Firefox\n"
          end

          it "does not write when value is the same" do
            allow(@input).to receive(:execute_command).and_return("Firefox", "Firefox")
            @input.watch_command(name: "window", command: "get_window", writer: @writer)
            @input.watch_command(name: "window", command: "get_window", writer: @writer)
            @writer.rewind
            expect(@writer.read).to eq "window:Firefox\n"
          end

          it "writes again when value changes" do
            allow(@input).to receive(:execute_command).and_return("Firefox", "Chrome")
            @input.watch_command(name: "window", command: "get_window", writer: @writer)
            @input.watch_command(name: "window", command: "get_window", writer: @writer)
            @writer.rewind
            expect(@writer.read).to eq "window:Firefox\nwindow:Chrome\n"
          end

          it "does not write when command fails" do
            allow(@input).to receive(:execute_command).and_return(nil)
            @input.watch_command(name: "window", command: "get_window", writer: @writer)
            @writer.rewind
            expect(@writer.read).to eq ""
          end
        end
      end
    end
  end
end
