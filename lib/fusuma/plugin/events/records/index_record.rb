# frozen_string_literal: true

module Fusuma
  module Plugin
    module Events
      module Records
        # Vector Record
        # have index
        class IndexRecord < Record
          # define gesture format
          attr_accessor :index
          attr_reader :position, :trigger, :args

          # @param [Config::Index] index
          # @param [Symbol] position [:prefix, :body, :surfix]
          # @param [Symbol] trigger [:oneshot, :repeat]
          def initialize(index:, position: :body, trigger: :oneshot, args: {})
            super()
            @index = index
            @position = position
            @trigger = trigger
            @args = args
          end

          def type
            :index
          end

          # FIXME: move to Config::Index
          # @param records [Array<IndexRecord>]
          # @return [IndexRecord] when merge is succeeded
          # @return [NilClass] when merge is not succeeded
          def merge(records:, index: @index)
            # FIXME: cache
            raise "position is NOT body: #{self}" unless mergable?

            if records.empty?
              if Config.find_executor_key(index)
                @index = index
                return self
              end
              return nil
            end

            sorted = records.sort_by(&:merge_priority)
            record = sorted.shift
            new_index = case record.position
                        when :prefix
                          Config::Index.new([*record.index.keys, *index.keys])
                        when :surfix
                          Config::Index.new([*index.keys, *record.index.keys])
                        else
                          raise "invalid index position: #{record}"
                        end

            return unless exist_on_conf?(new_index)

            merge(records: sorted, index: new_index)
          end

          # @param [Config::Searcher] searcher
          def exist_on_conf?(index = @index)
            Config.search(index)
          end

          def merge_priority
            case @position
            when :prefix
              10
            when :surfix
              100
            else
              1000
            end
          end

          # @return [Integer]
          def trigger_priority
            case @trigger
            when :oneshot
              10
            when :repeat
              100
            else
              1000
            end
          end

          def mergable?
            @position == :body
          end
        end
      end
    end
  end
end
