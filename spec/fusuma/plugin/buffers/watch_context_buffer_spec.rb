# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/buffers/watch_context_buffer"
require "./lib/fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Buffers
      RSpec.describe WatchContextBuffer do
        before do
          @buffer = WatchContextBuffer.new
        end

        describe "class" do
          it "inherits from Buffer" do
            expect(WatchContextBuffer.superclass).to eq Buffer
          end
        end

        describe "#source" do
          it "returns DEFAULT_SOURCE" do
            expect(@buffer.source).to eq "watch_context_input"
          end
        end

        describe "#type" do
          it "returns watch_context" do
            expect(@buffer.type).to eq "watch_context"
          end
        end
      end
    end
  end
end
