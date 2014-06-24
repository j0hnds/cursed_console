module CursedConsole

  class WebServiceClient

    attr_reader :host, :ssl, :api_token, :trace

    def initialize(host, ssl, api_token, trace=false)
      @host = host
      @ssl = ssl
      @api_token = api_token
      @trace = trace
    end

    def get(uri, is_json=true)
      invoke_rest(is_json) do
        result = RestClient.get(build_url(uri),
                                authentication_headers)
      end
    end

    def delete(uri, is_json=true)
      invoke_rest(is_json) do
        result = RestClient.delete(build_url(uri),
                                  authentication_headers)
      end
    end

    def post(uri, parameters, is_json=true)
      invoke_rest(is_json) do
        result = RestClient.post(build_url(uri),
                                parameters,
                                authentication_headers)
      end
    end

    def put(uri, parameters, is_json=true)
      invoke_rest(is_json) do
        result = RestClient.put(build_url(uri),
                                parameters,
                                authentication_headers)
      end
    end

    private

    def invoke_rest(is_json=true)
      begin
        response = yield
        begin
          is_json ? JSON.parse(response) : response
        rescue Exception => ex
          puts "Error parsing response: #{ex.message[0..100]}"
          if trace 
            puts "Full Error message: #{ex.message}"
            puts "\t#{ex.backtrace.join("\n\t")}"
          end
          # exit 1
          raise "Error parsing response: #{ex.message[0..100]}"
        end
      rescue RestClient::Exception => ex
        puts "Response: #{ex.response.code} - #{ex.response.description}"
        if [ 403, 404 ].include?(ex.response.code)
          if is_json
            begin
              hash = JSON.parse(ex.response.http_body)
              if hash.has_key?('error')
                puts(hash['error'])
              elsif hash.has_key?('validation_error')
                puts "Validation errors:"
                hash['validation_error'].each_pair do | key, value |
                  puts "  #{key}"
                  puts "    #{value.join("\n    ")}"
                end
              else
                puts(hash.inspect)
              end
            rescue Exception => json_ex
              raise "Unable to parse body for error: #{ex.response.http_body[0..50]}"
            end
          end
        end
        # exit 1
      rescue SystemExit
        raise
      rescue Exception => ex
        # General unknown exception
        raise "Error invoking RestClient: #{ex.message}"
        # puts "\t#{ex.backtrace.join("\n\t")}" if trace
        # exit 1
      end
    end

    def build_url(uri)
      "#{ssl ? 'https' : 'http'}://#{host}/#{uri}"
    end

    def authentication_headers
      {
        'Authorization' => "Token token=\"#{api_token}\""
      }
    end
  end

end
