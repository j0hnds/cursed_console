require 'optparse'

module CursedConsole

  class Options

    DEFAULT_USE_SSL = true
    DEFAULT_TOKEN = ENV['API_TOKEN']

    def initialize(app_name="cursed_console")
      @options = {}
      @app_name = app_name

      @optparse = OptionParser.new do | opts |
        # Set a banner, displayed at the top of the help screen
        opts.banner = "Usage: #{@app_name} [ options ] [ resource [ action ] ]"

        opts.on '-h', '--help', 'Display the usage message' do
          puts opts
        end

        opts.on '-s', '--server SERVER', 'Specify the RESTful web server' do | server |
          @options[:server] = server
        end

        @options[:use_ssl] = DEFAULT_USE_SSL
        opts.on '-n', '--no-ssl', 'If specified, SSL will NOT be used for the call to the server' do
          @options[:use_ssl] = false
        end 

        @options[:api_token] = DEFAULT_TOKEN
        opts.on '-t', '--token TOKEN', 'The API security token to use (defaults to ENV["API_TOKEN"])' do | token |
          @options[:api_token] = token
        end

        opts.on '-p', '--plugin-path PATH', 'The path to the plugins' do | path |
          @options[:plugin_path] = path
        end
      end
    end

    def parse_options!(argv=ARGV)
      @optparse.parse!(argv)

      # Check the API token
      raise "Must specify an API token either via the environment variable 'API_TOKEN' or via the -t option" if @options[:api_token].nil?

      # Check the plugin-path
      raise "Must specify a plugin path" if @options[:plugin_path].nil?
      raise "The specified plugin path does not exist" if ! File.exists?(@options[:plugin_path])

      @options
    rescue
      puts @optparse
      puts
      puts $!.message
      puts
      exit
    end

  end

end
