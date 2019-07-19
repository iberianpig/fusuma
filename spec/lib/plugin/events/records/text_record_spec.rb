# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/events/records/text_record.rb'

module Fusuma
  module Plugin
    module Events
      module Records
        RSpec.describe TextRecord do
          let(:record) { described_class.new('this is dummy') }

          describe '#type' do
            subject { record.type }
            it { is_expected.to eq :text }
          end

          describe '#to_s' do
            subject { record.to_s }
            it { is_expected.to eq 'this is dummy' }
          end
        end
      end
    end
  end
end
