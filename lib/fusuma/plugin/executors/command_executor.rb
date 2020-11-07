# frozen_string_literal: true

require 'posix/spawn'
require_relative './executor.rb'

module Fusuma
  module Plugin
    module Executors
      # Exector plugin
      class CommandExecutor < Executor
        def execute(event)
          search_command(event).tap do |command|
            break unless command

            MultiLogger.info(command: command)

            pid = POSIX::Spawn.spawn(command.to_s)
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
      end
    end
  end
end
