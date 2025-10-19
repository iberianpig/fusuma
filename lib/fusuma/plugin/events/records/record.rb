# frozen_string_literal: true

require_relative "../../base"

module Fusuma
  module Plugin
    module Events
      module Records
        # Record
        # @abstract Subclass and override {#type} to implement
        class Record < Base
          # @return [Symbol]
          #: () -> nil
          def type
            raise NotImplementedError, "override #type"
          end
        end
      end
    end
  end
end
