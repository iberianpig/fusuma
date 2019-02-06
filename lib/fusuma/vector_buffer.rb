require_relative 'command_executor'

module Fusuma
  # manage vectors and generate command
  class VectorBuffer
    def initialize(*args)
      @vectors = Array.new(*args)
      @prev_vectors = []
    end

    # @return [CommandExecutor, nil]
    def generate_command_executor
      # TODO: implements Multi-Vectors Command
      vector = @vectors.first
      @prev_vectors = @vectors
      @vectors.clear
      CommandExecutor.new(vector)
    end

    # @param vector [GestureVector]
    def push(vector)
      @vectors.push(vector)
    end
    alias << push
  end
end
