# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/custom_process"

module Fusuma
  RSpec.describe CustomProcess do
    before do
      test_klass = Class.new do
        include CustomProcess

        def call
          fork { puts "hoge" }
        end
      end
      stub_const("TestKlass", test_klass)
    end

    describe ".fork" do
      before do
        @test_instance = TestKlass.new
        allow(Process).to receive(:fork).and_yield do |block_context|
          allow(block_context).to receive(:proctitle).and_return(@test_instance.proctitle)
          allow(Process).to receive(:setproctitle).with(@test_instance.proctitle)
        end
      end

      it "call Process.fork" do
        @test_instance.call
        expect(Process).to have_received(:fork)
      end

      it "Process.setproctitle" do
        @test_instance.call
        expect(Process).to have_received(:setproctitle).with(@test_instance.proctitle)
      end
    end
  end
end
