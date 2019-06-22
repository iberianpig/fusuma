# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/formats/records/gesture_record.rb'

module Fusuma
  module Plugin
    module Formats
      module Records
        RSpec.describe GestureRecord do
          let(:record) do
            described_class.new(status: 'updating',
                                gesture: 'swipe',
                                finger: 3,
                                direction: direction)
          end
          let(:direction) { GestureRecord::Direction.new(0, 0, 1, 0) }

          describe '#type' do
            subject { record.type }
            it { is_expected.to eq :gesture }
          end
        end
      end
    end
  end
end
