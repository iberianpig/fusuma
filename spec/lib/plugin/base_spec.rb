# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/base.rb'
require './lib/fusuma/plugin/manager.rb'

module Fusuma
  module Plugin
    class DummyPlugin < Base
      def config_param_types
        {
          dummy_string: String,
          dummy_list: Array,
          dummy_bool: [TrueClass, FalseClass]
        }
      end
    end

    class DummyChildPlugin < DummyPlugin
    end

    RSpec.describe DummyPlugin do
      before do
        @dummy_plugin = DummyPlugin.new
        @dummy_child_plugin = DummyChildPlugin.new

        ConfigHelper.load_config_yml = <<-CONFIG
        plugin:
          dummy_plugin:
            dummy_string: dummy
            dummy_list:
              - 1
              - 2
              - 3
            dummy_bool: true
        CONFIG
      end

      after do
        Config.custom_path = nil
      end
      describe '.inherited' do
        it 'should add required class to subclass on Manager' do
          expect(Manager.plugins[Base.name]).to include(DummyPlugin)
        end
      end

      describe '.plugins' do
        it 'should list plugins' do
          expect(DummyPlugin.plugins).to eq([DummyChildPlugin])
        end
      end

      describe '#config_param_types' do
        it 'should define class for config params' do
          expect(@dummy_plugin.config_param_types).to be_a Hash
        end
      end

      describe '#config_params' do
        it 'should fetch options from config' do
          expect(@dummy_plugin.config_params).to be_a Hash
          expect(@dummy_plugin.config_params(:dummy_string)).to be_a String
        end
      end

      describe '#config_index' do
        it 'should return index' do
          expect(@dummy_plugin.config_index).to be_a Config::Index
        end
      end
    end
  end
end
