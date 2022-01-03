# frozen_string_literal: true

require 'fusuma/string_support'

module Fusuma
  # Rename process
  module CustomProcess
    def fork
      Process.fork do
        Process.setproctitle(self.class.name.underscore.to_s)
        yield
      end
    end
  end
end
