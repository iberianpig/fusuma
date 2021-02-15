# frozen_string_literal: true

require 'posix/spawn'
require_relative './executor'

module Fusuma
  module Plugin
    module Executors
      # Exector plugin
      class CommandExecutor < Executor
        def execute(event)
          search_command(event).tap do |command|
            break unless command

            MultiLogger.info(command: command, args: event.record.args)

            additional_env = event.record.args
                                  .deep_transform_keys(&:to_s)
                                  .deep_transform_values { |v| (v * args_accel(event)).to_s }

            pid = POSIX::Spawn.spawn(additional_env, command.to_s)
            Process.detach(pid)
          end
        end

        def executable?(event)
          event.tag.end_with?('_detector') &&
            event.record.type == :index &&
            search_command(event)
        end

        # @param event [Event]
        # @return [String]
        def search_command(event)
          command_index = Config::Index.new([*event.record.index.keys, :command])
          Config.search(command_index)
        end

        # @param event [Event]
        # @return [Float]
        def args_accel(event)
          accel_index = Config::Index.new([*event.record.index.keys, :accel])
          (Config.search(accel_index) || 1).to_f
        end
      end
    end
  end
end
