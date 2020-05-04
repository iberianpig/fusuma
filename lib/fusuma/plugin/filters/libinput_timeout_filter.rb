# frozen_string_literal: true

require_relative './filter.rb'
require_relative '../../libinput_command.rb'

module Fusuma
  module Plugin
    module Filters
      # Filter device log
      class LibinputTimeoutFilter < Filter
        DEFAULT_SOURCE = 'libinput_command_input'

        # @return [TrueClass] when keeping it
        # @return [FalseClass] when discarding it
        def keep?(record)
          record.to_s == LibinputCommand::TIMEOUT_MESSAGE
        end
      end
    end
  end
end
