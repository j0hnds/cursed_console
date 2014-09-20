module CursedConsole

  class WebServiceException < Exception
    attr_reader :inner_exception

    def initialize(message, ex=nil)
      super message
      @inner_exception = ex
    end

  end

end
