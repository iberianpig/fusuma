# frozen_string_literal: true

require_relative "executor"

module Fusuma
  module Plugin
    module Executors
      # Exector plugin
      class CommandExecutor < Executor
        # Executor parameter on config.yml
        # @return [Array<Symbol>]
        def execute_keys
          [:command]
        end

        #: (Fusuma::Plugin::Events::Event) -> void
        def execute(event)
          command = search_command(event)

          MultiLogger.info(command: command, args: event.record.args)

          accel = args_accel(event)
          additional_env = event.record.args
            .deep_transform_keys(&:to_s)
            .deep_transform_values { |v| (v * accel).to_s }

          pid = Process.spawn(additional_env, command.to_s)
          Process.detach(pid)
        rescue SystemCallError => e
          MultiLogger.error("#{event.record.index.keys}: #{e.message}")
        end

        #: (Fusuma::Plugin::Events::Event) -> (String | bool)
        def executable?(event)
          event.tag.end_with?("_detector") &&
            event.record.type == :index &&
            search_command(event)
        end

        # @param event [Event]
        # @return [String]
        #: (Fusuma::Plugin::Events::Event) -> String
        def search_command(event)
          command_index = Config::Index.new([*event.record.index.keys, :command])
          Config.instance.search(command_index)
        end

        # @param event [Event]
        # @return [Float]
        #: (Fusuma::Plugin::Events::Event) -> Float
        def args_accel(event)
          accel_index = Config::Index.new([*event.record.index.keys, :accel])
          (Config.instance.search(accel_index) || 1).to_f
        end
      end
    end
  end
end
