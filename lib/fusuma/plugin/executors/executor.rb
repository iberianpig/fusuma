# frozen_string_literal: true

require_relative '../base'

module Fusuma
  module Plugin
    # executor class
    module Executors
      # Inherite this base
      class Executor < Base
        BASE_ONESHOT_INTERVAL = 0.3
        BASE_REPEAT_INTERVAL = 0.1

        # Executor parameter on config.yml
        # @return [Array<Symbol>]
        def execute_keys
          # [name.split('Executors::').last.underscore.gsub('_executor', '').to_sym]
          raise NotImplementedError, "override #{name}##{__method__}"
        end

        # check executable
        # @param _event [Events::Event]
        # @return [TrueClass, FalseClass]
        def executable?(_event)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @param event [Events::Event]
        # @param time [Time]
        # @return [TrueClass, FalseClass]
        def enough_interval?(event)
          # NOTE: Cache at the index that is actually used, reflecting Fallback and Skip.
          #       Otherwise, a wrong index will cause invalid intervals.
          return true if event.record.index.with_context.keys.any? { |key| key.symbol == :end }

          return false if @wait_until && event.time < @wait_until

          true
        end

        def update_interval(event)
          @wait_until = event.time + interval(event).to_f
        end

        def interval(event)
          @interval_time ||= {}
          index = event.record.index
          @interval_time[index.cache_key] ||= begin
            config_value =
              Config.search(Config::Index.new([*index.keys, 'interval'])) ||
              Config.search(Config::Index.new(['interval', Detectors::Detector.type(event.tag)]))
            if event.record.trigger == :oneshot
              (config_value || 1) * BASE_ONESHOT_INTERVAL
            else
              (config_value || 1) * BASE_REPEAT_INTERVAL
            end
          end
        end

        # execute something
        # @param _event [Event]
        # @return [nil]
        def execute(_event)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end
      end
    end
  end
end
