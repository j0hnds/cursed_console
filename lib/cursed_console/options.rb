require 'optparse'

module CursedConsole

  class Options

    # Use either the new token (if supplied) or the old one.
    # Better support for legacy usage.
    DEFAULT_TOKEN = ENV['CURSED_API_TOKEN'] || ENV['API_TOKEN']
    DEFAULT_PLUGIN_PATH = ENV['CURSED_PLUGIN_PATH']
    DEFAULT_SERVER = ENV['CURSED_SERVER']
    DEFAULT_USE_SSL = ENV['CURSED_USE_SSL']

    def initialize(app_name="cursed_console")
      @options = {}
      @app_name = app_name

      @optparse = OptionParser.new do | opts |
        # Set a banner, displayed at the top of the help screen
        opts.banner = "Usage: #{@app_name} [ options ] [ resource [ action ] ]"

        opts.on '-h', '--help', 'Display the usage message' do
          puts opts
          exit
        end

        @options[:server] = DEFAULT_SERVER
        opts.on '-s', '--server SERVER', 'Specify the RESTful web server' do | server |
          @options[:server] = server
        end

        @options[:use_ssl] = DEFAULT_USE_SSL == 'true'
        opts.on '-n', '--no-ssl', 'If specified, SSL will NOT be used for the call to the server' do
          @options[:use_ssl] = false
        end 

        @options[:api_token] = DEFAULT_TOKEN
        opts.on '-t', '--token TOKEN', 'The API security token to use (defaults to ENV["API_TOKEN"])' do | token |
          @options[:api_token] = token
        end

        @options[:plugin_path] = DEFAULT_PLUGIN_PATH
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
