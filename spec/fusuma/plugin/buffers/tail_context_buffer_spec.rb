# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/buffers/tail_context_buffer"
require "./lib/fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Buffers
      RSpec.describe TailContextBuffer do
        before do
          @buffer = TailContextBuffer.new
        end

        describe "class" do
          it "inherits from Buffer" do
            expect(TailContextBuffer.superclass).to eq Buffer
          end
        end

        describe "#source" do
          it "returns DEFAULT_SOURCE" do
            expect(@buffer.source).to eq "tail_context_input"
          end
        end

        describe "#type" do
          it "returns tail_context" do
            expect(@buffer.type).to eq "tail_context"
          end
        end
      end
    end
  end
end
