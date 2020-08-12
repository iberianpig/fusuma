# frozen_string_literal: true

require_relative '../../libinput_command.rb'
require_relative './input.rb'

module Fusuma
  module Plugin
    module Inputs
      # libinput commands wrapper
      class LibinputCommandInput < Input
        def config_param_types
          {
            'device': [String],
            'enable-dwt': [TrueClass, FalseClass],
            'enable-tap': [TrueClass, FalseClass],
            'show-keycodes': [TrueClass, FalseClass],
            'verbose': [TrueClass, FalseClass],
            'libinput-debug-events': [String],
            'libinput-list-devices': [String]
          }
        end

        def io
          @io ||= command.debug_events
        end

        def command
          @command ||= LibinputCommand.new(
            libinput_options: libinput_options,
            commands: {
              debug_events_command: debug_events_command,
              list_devices_command: list_devices_command
            }
          )
        end

        def libinput_options
          device = ("--device='#{config_params(:device)}'" if config_params(:device))
          enable_tap = '--enable-tap' if config_params(:'enable-tap')
          enable_dwt = '--enable-dwt' if config_params(:'enable-dwt')
          show_keycodes = '--show-keycodes' if config_params(:'show-keycodes')
          verbose = '--verbose' if config_params(:verbose)
          [
            device,
            enable_dwt,
            enable_tap,
            show_keycodes,
            verbose
          ].compact
        end

        def debug_events_command
          config_params(:'libinput-debug-events')
        end

        def list_devices_command
          config_params(:'libinput-list-devices')
        end
      end
    end
  end
end
