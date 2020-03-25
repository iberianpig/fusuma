# frozen_string_literal: true

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
            'verbose': [TrueClass, FalseClass]
          }
        end

        def run
          LibinputCommand.new(libinput_options: libinput_options).debug_events do |line|
            yield event(record: line)
          end
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
      end
    end
  end
end
