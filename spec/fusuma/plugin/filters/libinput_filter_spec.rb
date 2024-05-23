# frozen_string_literal: true

require "spec_helper"

require "./lib/fusuma/config"
require "./lib/fusuma/plugin/filters/libinput_device_filter"
require "./lib/fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Filters
      RSpec.describe LibinputDeviceFilter do
        before do
          @filter = LibinputDeviceFilter.new
        end

        describe "#source" do
          it { expect(@filter.source).to eq LibinputDeviceFilter::DEFAULT_SOURCE }

          context "with config" do
            around do |example|
              @custom_source = "custom_input"

              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                 filters:
                   libinput_device_filter:
                     source: #{@custom_source}
              CONFIG

              example.run

              Config.custom_path = nil
            end

            it { expect(@filter.source).to eq @custom_source }
          end
        end

        describe "#filter" do
          before do
            @event = Events::Event.new(tag: "libinput_command_input", record: "dummy")
          end

          context "when filter#keep? return false" do
            before do
              allow(@filter).to receive(:keep?).and_return(false)
            end

            it { expect(@filter.filter(@event)).to be nil }
          end

          context "when filter#keep? return true" do
            before do
              allow(@filter).to receive(:keep?).and_return(true)
            end

            it { expect(@filter.filter(@event)).to be @event }
          end
        end

        describe "#keep?" do
          before do
            device = Device.new(id: "event18", name: "Awesome Touchpad", available: true)
            allow(Device).to receive(:all).and_return([device])
            @keep_device = LibinputDeviceFilter::KeepDevice.new(name_patterns: [])
            allow(@filter).to receive(:keep_device).and_return(@keep_device)
          end

          context "when including record generated from touchpad" do
            before do
              text = " event18  GESTURE_SWIPE_UPDATE  +1.44s  4 11.23/ 1.00 (36.91/ 3.28 unaccelerated) "
              @event = Events::Event.new(tag: "libinput_command_input", record: text)
            end
            it "should keep record" do
              expect(@filter.keep?(@event.record)).to be true
            end

            context "when including -" do
              before do
                text = "-event18  GESTURE_SWIPE_UPDATE  +1.44s  4 11.23/ 1.00 (36.91/ 3.28 unaccelerated) "
                @event = Events::Event.new(tag: "libinput_command_input", record: text)
              end
              it "should keep record" do
                expect(@filter.keep?(@event.record)).to be true
              end
            end
          end
          context "when new device is added" do
            before do
              text = "-event18 DEVICE_ADDED Apple Wireless Trackpad seat0 default group13 cap:pg size 132x112mm tap(dl off) left scroll-nat scroll-2fg-edge click-buttonareas-clickfing "
              @event = Events::Event.new(tag: "libinput_command_input", record: text)
            end
            it "should reset KeepDevice" do
              expect(@keep_device).to receive(:reset)
              @filter.keep?(@event.record)
            end

            it "discard DEVICE_ADDED record" do
              expect(@filter.keep?(@event.record)).to be false
            end

            context "when keep device is NOT matched" do
              before do
                @keep_device = LibinputDeviceFilter::KeepDevice.new(name_patterns: ["Microsoft Arc Mouse"])
                allow(@filter).to receive(:keep_device).and_return(@keep_device)
              end
              it "should NOT reset KeepDevice" do
                expect(@keep_device).not_to receive(:reset)
                # NOTE: @event.record is 'Apple Wireless Touchpad'
                @filter.keep?(@event.record)
              end
            end
          end
        end
      end
    end
  end
end
