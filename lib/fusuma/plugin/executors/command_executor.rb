module Fusuma
  module Plugin
    module Executors
      class CommandExecutor < Executor

        def execute(event)
          command = search_command(event)
          `#{command}`
        end

        def executable?(event)
          search_command(event) && super
        end

        # @param event [Event]
        # @return [String]
        def search_command(event)
          search_index = index(event)
          command = Config.command(search_index)
          command
        end

        # @example
        #  index
        #  =>[:swipe, :3, left, :command]
        # @param event [Event]
        # @return [String]
        def index(event)
          gesture_type = event.class::TYPE
          finger       = event.finger
          direction    = event.direction
          [gesture_type, finger, direction]
        end
      end
    end
  end
end
