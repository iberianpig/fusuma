# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        # Vector Record
        # have index
        class IndexRecord < Record
          # define gesture format
          attr_reader :index
          attr_reader :position

          # @param [Config::Index] index
          # @param [Symbol] position [:prefix, :body, :surfix]
          def initialize(index:, position: :body)
            super()
            @index = index
            @position = position
          end

          def type
            :index
          end

          # @param records [Array<IndexRecord>]
          # @return [IndexRecord]
          def merge(records:)
            raise "position is NOT body: #{self}" unless mergable?

            @index = records.reduce(@index) do |merged_index, record|
              case record.position
              when :prefix
                Config::Index.new([*record.index.keys, *merged_index.keys])
              when :surfix
                Config::Index.new([*merged_index.keys, *record.index.keys])
              else
                raise "invalid index position: #{record}"
              end
            end
            self
          end

          def mergable?
            @position == :body
          end
        end
      end
    end
  end
end
