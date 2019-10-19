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

        # @return [TrueClass] when keeping it
        # @return [FalseClass] when discarding it
        def keep?(record)
          # NOTE: purge cache when found new device
          if record.to_s =~ /\sDEVICE_ADDED\s/ && keep_device.match_pattern?(record.to_s)
            keep_device.reset
            return false
          end

          keep_device.all.map(&:id).any? { |device_id| record.to_s =~ /^\s?#{device_id}\s/ }
        end

        def keep_device
          @keep_device ||= begin
                             from_config = Array(config_params(:keep_device_names))
                             KeepDevice.new(name_patterns: from_config)
                           end
        end

        # Select Device to keep
        class KeepDevice
          def initialize(name_patterns:)
            @name_patterns = name_patterns | Array(self.class.from_option)
          end

          # remove cache for reloading new devices
          def reset
            @all = nil
            Device.reset
          end

          # @return [Array]
          def all
            @all ||= if @name_patterns.empty?
                       Device.available
                     else
                       Device.all.select do |device|
                         match_pattern?(device.name)
                       end
                     end
          end

          # @return [TrueClass]
          # @return [FalseClass]
          def match_pattern?(string)
            return true if @name_patterns.empty?

            @name_patterns.any? { |name_pattern| string.match(name_pattern) }
          end

          class << self
            # TODO: remove from_option and command line options
            attr_accessor :from_option
          end
        end
      end
    end
  end
end
