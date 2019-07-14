# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/parsers/parser.rb'
require './lib/fusuma/plugin/formats/event_format.rb'

module Fusuma
  module Plugin
    module Parsers
      class DummyParser < Parser
        DEFAULT_SOURCE = 'dummy_input'
      end

      RSpec.describe Parser do
        let(:parser) { DummyParser.new }

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            plugin:
             parsers:
               dummy_parser:
                 dummy: dummy
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe '#source' do
          subject { parser.source }

          it { is_expected.to be DummyParser::DEFAULT_SOURCE }
        end

        describe '#parse' do
          subject { parser.parse(event) }
          let(:event) { Formats::Event.new(tag: 'dummy_input', record: 'dummy') }

          it { is_expected.to be event }
        end
      end
    end
  end
end
