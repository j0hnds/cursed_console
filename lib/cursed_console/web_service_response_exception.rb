module CursedConsole

  class WebServiceResponseException < Exception

    attr_reader :inner_exception

    def initialize(message, ex)
      super message
      @inner_exception = ex
    end

    def response_code
      inner_exception.response.code
    end

    def response_body
      inner_exception.response.http_body
    end

    def json_response_body
      JSON.parse response_body
    rescue 
      []
    end

  end

end
