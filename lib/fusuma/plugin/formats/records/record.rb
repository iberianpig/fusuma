# frozen_string_literal: true

require_relative '../format.rb'

module Fusuma
  module Plugin
    module Formats
      module Records
        # Record Format
        # @abstract Subclass and override {#type} to implement
        class Record < Format
          # @return [Symbol]
          def type
            raise NotImplementedError, 'override #type'
          end
        end
      end
    end
  end
end
