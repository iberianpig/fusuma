# frozen_string_literal: true

require "tempfile"
require "./lib/fusuma/config"

module Fusuma
  module ConfigHelper
    module_function

    #: (String) -> Tempfile
    def load_config_yml=(string)
      Config.custom_path = Tempfile.open do |temp_file|
        temp_file.tap { |f| f.write(string) }
      end
    end

    #: () -> nil
    def clear_config_yml
      Config.custom_path = nil
    end
  end
end
