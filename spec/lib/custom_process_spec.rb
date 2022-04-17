# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/custom_process'

module Fusuma
  RSpec.describe CustomProcess do
    class ForkTest
      include CustomProcess

      def call
        fork { puts 'hoge' }
      end
    end

    describe '.fork' do
      before do
        @test_instance = ForkTest.new
      end
      it 'call Process.fork and Process.setproctitle' do
        expect(Process).to receive(:fork).and_yield do |block_context|
          allow(block_context).to receive(:proctitle).and_return(@test_instance.proctitle)
          expect(Process).to receive(:setproctitle).with(@test_instance.proctitle)
        end
        @test_instance.call
      end
    end
  end
end
