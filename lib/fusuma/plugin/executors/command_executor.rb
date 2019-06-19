# frozen_string_literal: true

require_relative './executor.rb'
require 'open3'

module Fusuma
  module Plugin
    module Executors
      # Exector plugin
      class CommandExecutor < Executor
        def execute(vector)
          search_command(vector).tap do |command|
            break unless command

            MultiLogger.info(command: command)
            pid = fork do
              Process.daemon(true)
              exec(command.to_s)
            end

            Process.detach(pid)
          end
        end

        def executable?(vector)
          search_command(vector)
        end

        # @param vector [Vector]
        # @return [String]
        def search_command(vector)
          Config.search(index(vector))
        end

        # @example
        #  index
        #  =>[:swipe, :3, left, :command]
        # @param vector [Vector]
        # @return [String]
        def index(vector)
          Config::Index.new [*vector.index.keys, 'command']
        end
      end
    end
  end
end
