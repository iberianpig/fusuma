# frozen_string_literal: true

require_relative "buffer"

module Fusuma
  module Plugin
    module Buffers
      # Buffers context events from WatchContextInput for detection
      class WatchContextBuffer < Buffer
        DEFAULT_SOURCE = "watch_context_input"
      end
    end
  end
end
