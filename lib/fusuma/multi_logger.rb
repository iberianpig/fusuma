# frozen_string_literal: true

# module as namespace
module Fusuma
  require 'logger'
  require 'singleton'
  # logger separate between stdout and strerr
  class MultiLogger < Logger
    include Singleton

    attr_reader :err_logger
    attr_accessor :debug_mode

    def initialize
      super(STDOUT)
      @err_logger = Logger.new(STDERR)
      @debug_mode = false
    end

    def info(msg)
      super(msg)
    end

    def debug(msg)
      return unless debug_mode?

      super(msg)
    end

    def warn(msg)
      err_logger.warn(msg)
    end

    def error(msg)
      err_logger.error(msg)
    end

    def debug_mode?
      debug_mode
    end

    class << self
      def info(msg)
        instance.info(msg)
      end

      def debug(msg)
        instance.debug(msg)
      end

      def warn(msg)
        instance.warn(msg)
      end

      def error(msg)
        instance.error(msg)
      end
    end
  end
end
