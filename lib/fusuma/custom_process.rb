# frozen_string_literal: true

module Fusuma
  # Rename process
  module CustomProcess
    def fork
      Process.fork do
        Process.setproctitle("fusuma: #{self.class.name}")
        yield
      end
    end
  end
end
