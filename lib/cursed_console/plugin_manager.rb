module CursedConsole

  class PluginManager

    attr_reader :plugin_path

    def initialize(plugin_path)
      @plugin_path = plugin_path
    end

    def sub_paths
      @sub_paths ||= identify_sub_paths
    end

    def actions(sub_path, plugin_name)
      "Plugins::#{sub_path.capitalize}::#{plugin_name.capitalize}".constantize.instance_methods(false)
    end

    def instantiate_plugin(sub_path, plugin_name)
      "Plugins::#{sub_path.capitalize}::#{plugin_name.capitalize}".constantize.new
    end

    def ruby_modules
      @ruby_modules ||= Dir.glob(File.join(plugin_path, "**/*.rb"))
    end

    def plugins_for(sub_path)
      Dir.glob(File.join(plugin_path, sub_path, "*.rb")).map do | path |
        File.basename(path).slice(0...-3)
      end
    end

    def is_valid_plugin_path?
      sub_paths.size > 0 && ruby_modules.size > 0
    end

    def load_plugins
      raise "Invalid plugin path" unless is_valid_plugin_path? 
      ruby_modules.each { | module_path | require module_path }
    end

    private

    def identify_sub_paths
      Dir.glob(File.join(plugin_path, "*")).inject([]) { | acc, pth | acc << File.basename(pth) if File.directory?(pth); acc }
    end

  end

end
