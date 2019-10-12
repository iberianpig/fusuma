# frozen_string_literal: true

require 'tempfile'
require './lib/fusuma/config.rb'

module Fusuma
  module ConfigHelper
    module_function

    def load_config_yml=(string)
      Config.custom_path = Tempfile.open do |temp_file|
        temp_file.tap { |f| f.write(string) }
      end
    end
  end
end
