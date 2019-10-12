# frozen_string_literal: true

require_relative '../base.rb'
require_relative '../events/event.rb'

module Fusuma
  module Plugin
    # input class
    module Inputs
      # Inherite this base
      class Input < Base
        def run
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        def event(record: 'dummy input')
          Events::Event.new(tag: tag, record: record).tap do |e|
            MultiLogger.debug(input_event: e)
          end
        end

        def tag
          self.class.name.split('Inputs::').last.underscore
        end
      end
    end
  end
end
