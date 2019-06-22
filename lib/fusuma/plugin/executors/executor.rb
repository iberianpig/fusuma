# frozen_string_literal: true

require_relative '../base.rb'

module Fusuma
  module Plugin
    # executor class
    module Executors
      # Inherite this base
      class Executor < Base
        # check executable
        # @param _vector [Vector]
        # @return [TrueClass, FalseClass]
        def executable?(_vector)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # execute somthing
        # @param _vector [Vector]
        # @return [nil]
        def execute(_vector)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end
      end
    end
  end
end
