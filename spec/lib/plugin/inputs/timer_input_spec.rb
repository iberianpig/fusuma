# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/plugin/inputs/timer_input.rb'

module Fusuma
  module Plugin
    module Inputs
      RSpec.describe TimerInput do
        before do
          @dummy_read = StringIO.new('dummy_read')
          @dummy_write = StringIO.new('dummy_write')
          @input = TimerInput.new
          allow(@input).to receive(:create_io).and_return [@dummy_read, @dummy_write]
          allow(@input).to receive(:fork)
          allow(Process).to receive(:detach).with(anything)
        end

        describe '#io' do
          it { expect(@input.io).to eq @dummy_read }

          it 'should call #create_io' do
            expect(@input).to receive(:create_io)
            expect(@input).to receive(:start)
            @input.io
          end
        end

        describe '#start' do
          it {
            expect(@input).to receive(:fork).and_yield do |block_context|
              expect(block_context).to receive(:timer_loop).with(@dummy_read, @dummy_write)
            end
            @input.start(@dummy_read, @dummy_write)
          }
        end
      end
    end
  end
end
