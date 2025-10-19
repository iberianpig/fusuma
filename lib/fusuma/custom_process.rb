# frozen_string_literal: true

require_relative "string_support"

module Fusuma
  # Rename process
  module CustomProcess
    attr_writer :proctitle

    #: () -> Array[untyped]
    def child_pids
      @child_pids ||= []
    end

    #: () { () -> void } -> nil
    def fork
      pid = Process.fork do
        Process.setproctitle(proctitle)
        set_trap # for child process
        yield
      end
      child_pids << pid
      pid
    end

    def shutdown
      child_pids.each do |pid|
        Process.kill("TERM", pid)
      rescue Errno::ESRCH, IOError
        # ignore
      end

      child_pids.each do |pid|
        Process.wait(pid)
      rescue Errno::ECHILD
        # ignore
      end
    end

    #: () -> String
    def proctitle
      @proctitle ||= self.class.name.underscore
    end

    def set_trap
      Signal.trap("INT") {
        shutdown
        exit
      } # Trap ^C
      Signal.trap("TERM") {
        shutdown
        exit 1
      } # Trap `Kill `
    end
  end
end
