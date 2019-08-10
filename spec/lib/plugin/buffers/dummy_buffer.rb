# frozen_string_literal: true

require './lib/fusuma/plugin/buffers/buffer.rb'

module Fusuma
  module Plugin
    module Buffers
      class DummyBuffer < Buffer
        DEFAULT_SOURCE = 'dummy'
      end
    end
  end
end
