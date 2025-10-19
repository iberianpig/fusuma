# frozen_string_literal: true

require "./lib/fusuma/plugin/buffers/buffer"

module Fusuma
  module Plugin
    module Buffers
      class DummyBuffer < Buffer
        DEFAULT_SOURCE = "dummy"

        #: () -> Hash[Symbol, Array[Class] | Class]
        def config_param_types
          {
            source: String,
            dummy: String
          }
        end
      end
    end
  end
end
