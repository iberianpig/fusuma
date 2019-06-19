# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/formats/format.rb'

module Fusuma
  module Plugin
    module Formats
      DUMMY_OPTIONS = { formats: { dummy_format: 'dummy' } }.freeze

      class DummyFormat < Format
      end

      RSpec.describe Format do
        let(:format) { DummyFormat.new }

        describe '#type' do
          subject { format.type }
          it { is_expected.to eq 'dummy' }
        end
      end
    end
  end
end
