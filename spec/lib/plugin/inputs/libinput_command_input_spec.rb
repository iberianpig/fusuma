# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/inputs/libinput_command_input.rb'

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe LibinputCommandInput do
        let(:input) { described_class.new }

        describe '#io' do
          before do
            @dummy_io = StringIO.new('dummy')
            libinput_command = instance_double(LibinputCommand)
            allow(LibinputCommand).to receive(:new).and_return(libinput_command)
            allow(libinput_command).to receive(:debug_events).and_return @dummy_io
          end

          it { expect(input.io).to eq @dummy_io }
        end

        describe '#libinput_options' do
          it { expect(input.libinput_options).to be_a Array }

          context 'when device: awesome_device is given as config_params' do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_command_input:
                      device: awesome device
              CONFIG

              example.run

              Config.custom_path = nil
            end
            it "contains --device='awesome device'" do
              expect(input.libinput_options).to be_include "--device='awesome device'"
            end
          end

          context 'when enable-tap: true is given as config_params' do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_command_input:
                      enable-tap: true
              CONFIG

              example.run

              Config.custom_path = nil
            end
            it 'contains --enable-tap' do
              expect(input.libinput_options).to be_include '--enable-tap'
            end
          end

          context 'when enable-dwt: true is given as config_params' do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_command_input:
                      enable-dwt: true
              CONFIG

              example.run

              Config.custom_path = nil
            end
            it 'contains --enable-dwt' do
              expect(input.libinput_options).to be_include '--enable-dwt'
            end
          end

          context 'when show-keycodes: true is given as config_params' do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_command_input:
                      show-keycodes: true
              CONFIG

              example.run

              Config.custom_path = nil
            end
            it 'contains --show-keycodes' do
              expect(input.libinput_options).to be_include '--show-keycodes'
            end
          end

          context 'when verbose: true is given as config_params' do
            around do |example|
              ConfigHelper.load_config_yml = <<~CONFIG
                plugin:
                  inputs:
                    libinput_command_input:
                      verbose: true
              CONFIG

              example.run

              Config.custom_path = nil
            end
            it 'contains --verbose' do
              expect(input.libinput_options).to be_include '--verbose'
            end
          end
        end
      end
    end
  end
end
