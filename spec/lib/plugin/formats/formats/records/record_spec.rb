require 'spec_helper'

module Fusuma
  module Plugin
    module Formats
      module Records
        RSpec.describe Record do
          class DummyRecord < Records::Record
            def type
              :dummy
            end
          end
          let(:record) { described_class.new }

          describe '#type' do
            it { expect { record.type }.to raise_error(NotImplementedError) }

            context 'override #type' do
              let(:record) { DummyRecord.new }
              it { expect { record.type }.not_to raise_error(NotImplementedError) }
              it { expect(ecord.type).to eq :dummy }
            end
          end
        end
      end
    end
  end
end
