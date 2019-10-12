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
            keep_device_names: [Array, String]
          }
        end

        def keep?(record)
          keep_device_ids.any? { |device_id| record.to_s =~ /^\s?#{device_id}/ }
        end

        private

        # @return [Array]
        def keep_device_ids
          @keep_device_ids ||= Device.all.select do |device|
            keep_device_names.any? { |name| device.name.match? name }
          end.map(&:id)
        end

        # @return [Array]
        def keep_device_names
          Array(config_params(:keep_device_names)).tap do |names|
            break Device.all.map(&:name) if names.empty?
          end
        end
      end
    end
  end
end
