# frozen_string_literal: true

require_relative "buffer"

module Fusuma
  module Plugin
    module Buffers
      # Buffers context events from TailContextInput for detection
      class TailContextBuffer < Buffer
        DEFAULT_SOURCE = "tail_context_input"
      end
    end
  end
end
