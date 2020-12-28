# frozen_string_literal: true

require 'spec_helper'
require './lib/fusuma/custom_process.rb'

module Fusuma
  RSpec.describe CustomProcess do

    class ForkTest
      include CustomProcess

      def call
        fork { puts "hoge" }
      end
    end


    describe '.fork' do
      before do
        allow(Process).to receive(:fork)
      end
      it 'call Process.fork and Process.setproctitle' do
        expect(Process).to receive(:fork).and_yield do
          expect(Process).to receive(:setproctitle)
        end
        ForkTest.new.call
      end
    end
  end
end
