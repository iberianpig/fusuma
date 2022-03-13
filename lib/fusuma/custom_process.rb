# frozen_string_literal: true

require "fusuma/string_support"

module Fusuma
  # Rename process
  module CustomProcess
    attr_writer :proctitle

    def fork
      Process.fork do
        Process.setproctitle(proctitle)
        yield
      end
    end

    def proctitle
      @proctitle ||= self.class.name.underscore
    end
  end
end
