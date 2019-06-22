# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/base.rb'
require './lib/fusuma/plugin/manager.rb'

module Fusuma
  module Plugin
    RSpec.describe Base do
      describe '.inherited' do
        it 'should add required class to subclass on Manager'
      end

      describe '.plugins' do
        it 'should list plugins'
      end

      describe '#config_params' do
        it 'should fetch options from config'
      end

      describe '#config_index' do
        it 'should return index'
      end
    end
  end
end
