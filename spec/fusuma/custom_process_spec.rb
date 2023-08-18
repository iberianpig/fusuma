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

        def set_trap_dummy
        end
      end
      stub_const("TestKlass", test_klass)
    end

    describe ".fork" do
      before do
        @test_instance = TestKlass.new
        allow(Process).to receive(:fork).and_yield do |block_context|
          @child_process = block_context
          allow(@child_process).to receive(:proctitle).and_return(@test_instance.proctitle)
          allow(Process).to receive(:setproctitle).with(@test_instance.proctitle)
          allow(@child_process).to receive(:set_trap).and_return(@test_instance.set_trap_dummy)
        end
      end

      it "call Process.fork" do
        @test_instance.call
        expect(Process).to have_received(:fork)
      end

      it "has child_pids" do
        @test_instance.call
        expect(@test_instance.child_pids.size).to eq 1
      end

      it "call Process.setproctitle" do
        @test_instance.call
        expect(Process).to have_received(:setproctitle).with(@test_instance.proctitle)
      end

      it "call set_trap" do
        @test_instance.call
        expect(@child_process).to have_received(:set_trap)
      end
    end
  end
end
