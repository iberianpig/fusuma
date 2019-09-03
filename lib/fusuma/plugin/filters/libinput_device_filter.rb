# frozen_string_literal: true

require_relative './filter.rb'
require_relative '../../device.rb'

module Fusuma
  module Plugin
    module Filters
      # Filter device log
      class LibinputDeviceFilter < Filter
        DEFAULT_SOURCE = 'libinput_command_input'

        def config_param_types
          {
            source: String,
            keep_device_ids: [Array, String]
          }
        end

        def keep?(record)
          keep_device_ids.any? { |device_id| record.to_s =~ /^\s?#{device_id}/ }
        end

        private

        def keep_device_ids
          @keep_device_ids ||= Array(config_params(:keep_device_ids)) || Device.ids
        end
      end
    end
  end
end
