# frozen_string_literal: true

require "tempfile"
require "./lib/fusuma/config"

module Fusuma
  module ConfigHelper
    module_function

    def load_config_yml=(string)
      Config.custom_path = Tempfile.open do |temp_file|
        temp_file.tap { |f| f.write(string) }
      end
    end

    def clear_config_yml
      Config.custom_path = nil
    end
  end
end
