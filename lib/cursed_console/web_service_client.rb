module CursedConsole

  class WebServiceClient

    attr_reader :host, :ssl, :api_token

    def initialize(host, ssl, api_token)
      @host = host
      @ssl = ssl
      @api_token = api_token
    end

    def get(uri, is_json=true)
      invoke_rest(is_json) do
        RestClient.get(build_url(uri), authentication_headers)
      end
    end

    def delete(uri, is_json=true)
      invoke_rest(is_json) do
        RestClient.delete(build_url(uri), authentication_headers)
      end
    end

    def post(uri, parameters, is_json=true)
      invoke_rest(is_json) do
        RestClient.post(build_url(uri), parameters, authentication_headers)
      end
    end

    def put(uri, parameters, is_json=true)
      invoke_rest(is_json) do
        RestClient.put(build_url(uri), parameters, authentication_headers)
      end
    end

    private

    def invoke_rest(is_json=true)
      begin
        response = yield
        is_json ? parse_json(response)  : response
      rescue RestClient::Exception => ex
        raise CursedConsole::WebServiceResponseException.new("Error response", ex)
      rescue SystemExit
        raise
      rescue Exception => ex
        raise CursedConsole::WebServiceException.new(ex.message, ex)
      end
    end

    def build_url(uri)
      "#{ssl ? 'https' : 'http'}://#{host}/#{uri}"
    end

    def parse_json(json_src)
      JSON.parse(json_src)
    rescue => ex
      raise CursedConsole::WebServiceException.new("Error parsing json", ex)
    end

    def authentication_headers
      {
        'Authorization' => "Token token=\"#{api_token}\""
      }
    end
  end

end
