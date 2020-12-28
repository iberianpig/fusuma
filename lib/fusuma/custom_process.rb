module Fusuma
  module CustomProcess
    def fork
      Process.fork { 
        Process.setproctitle('fusuma: #%s' % self.class)
        yield
      }
    end
  end
end

