# frozen_string_literal: true

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
            pid = fork do
              Process.daemon(true)
              exec(command.to_s)
            end

            Process.detach(pid)
          end
        end

        def executable?(event)
          event.tag.match?(/_detector/) &&
            event.record.type == :vector &&
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
