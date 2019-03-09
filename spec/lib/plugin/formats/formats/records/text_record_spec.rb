require 'spec_helper'

module Fusuma
  module Plugin
    module Formats
      module Records
        RSpec.describe Text do
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
