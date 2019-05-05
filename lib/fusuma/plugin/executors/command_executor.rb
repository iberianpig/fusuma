require_relative './executor.rb'

module Fusuma
  module Plugin
    module Executors
      # Exector plugin
      class CommandExecutor < Executor
        def execute(vector)
          search_command(vector).tap do |command|
            break unless command

            _o, _e, s = Open3.capture3(command)
            return s.success?
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
