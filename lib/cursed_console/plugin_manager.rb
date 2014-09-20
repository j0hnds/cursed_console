module CursedConsole

  class PluginManager

    attr_reader :plugin_path

    def initialize(plugin_path)
      @plugin_path = plugin_path
    end

    def plugins
      @plugins ||= identify_plugins
    end

    def actions_for(plugin, resource)
      resource_class_name(plugin, resource).
        instance_methods(false).
        map { |m| m.to_s }
    end

    def instantiate_resource(plugin, resource)
      resource_class_name(plugin, resource).
        new
    end

    def resources_for(plugin)
      Dir.glob(File.join(plugin_path, plugin, "*.rb")).map do | path |
        File.basename(path).slice(0...-3)
      end
    end

    def is_valid_plugin_path?
      plugins.size > 0 && resource_modules.size > 0
    end

    def load_resources
      raise "Invalid plugin path" unless is_valid_plugin_path? 
      resource_modules.each { | module_path | require module_path }
    end

    private

    def resource_class_name(plugin, resource)
      "Plugins::#{plugin.capitalize}::#{resource.capitalize}".
        constantize
    end
  
    def resource_modules
      @resource_modules ||= Dir.glob(File.join(plugin_path, "**/*.rb"))
    end

    def identify_plugins
      Dir.glob(File.join(plugin_path, "*")).inject([]) do | acc, pth | 
        acc << File.basename(pth) if File.directory?(pth) 
        acc 
      end
    end

  end

end
