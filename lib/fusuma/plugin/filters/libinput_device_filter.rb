# frozen_string_literal: true

require_relative "./filter"
require_relative "../../device"

module Fusuma
  module Plugin
    module Filters
      # Filter device log
      class LibinputDeviceFilter < Filter
        DEFAULT_SOURCE = "libinput_command_input"

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
          # keep_device.all.map(&:id).any? { |device_id| record.to_s =~ /^[\s-]?#{device_id}\s/ }
          keep_device.filter_record(record)
        end

        def keep_device
          @keep_device ||= begin
            from_config = Array(config_params(:keep_device_names))
            KeepDevice.new(name_patterns: from_config)
          end
        end

        def config_param_sample
          <<~SAMPLE
            ```config.yml
            plugin:
              filters:
                libinput_device_filter:
                  keep_device_names:
                    - "DEVICE NAME PATTERN"
            ```
          SAMPLE
        end

        # Select Device to keep
        class KeepDevice
          def initialize(name_patterns:)
            @name_patterns = name_patterns | Array(self.class.from_option)
          end

          attr_reader :name_patterns

          # remove cache for reloading new devices
          def reset
            @all = @accept_any = nil
            Device.reset
          end

          def filter_record(record)
            @accept_any || all.any? { |device| record.to_s =~ /^[\s-]?#{device.id}\s/ }
          end

          # @return [Array]
          def all
            @all ||= if @name_patterns.empty?
              @accept_any = true
              Device.available
            else
              Device.all.select do |device|
                match_pattern?(device.name)
              end
            end.tap do |devices|
              print_not_found_messages if devices.empty?
            end
          end

          def print_not_found_messages
            puts "Device is not found. Check following section on your config.yml"
            puts LibinputDeviceFilter.new.config_param_sample
          end

          # @return [TrueClass]
          # @return [FalseClass]
          def match_pattern?(string)
            return true if @name_patterns.empty?

            @name_patterns.any? { |name_pattern| string.match(name_pattern) }
          end

          class << self
            attr_reader :from_option

            # TODO: remove from_option and command line options
            def from_option=(device)
              if device
                warn <<~COMMENT
                  Don't use --device="Device name" option because it is deprecated.
                  Use the options below instead.

                  #{LibinputDeviceFilter.new.config_param_sample}
                COMMENT
              end
              @from_option = device
            end
          end
        end
      end
    end
  end
end
