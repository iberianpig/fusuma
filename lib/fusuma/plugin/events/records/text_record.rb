# frozen_string_literal: true

require_relative './record.rb'

module Fusuma
  module Plugin
    module Events
      module Records
        # Default Record
        class TextRecord < Record
          # @param text [String]
          def initialize(text)
            @text = text
          end

          def type
            :text
          end

          # @return [String]
          def to_s
            @text
          end
        end
      end
    end
  end
end
