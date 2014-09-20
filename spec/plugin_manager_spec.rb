require 'spec_helper'

describe CursedConsole::PluginManager do
  include FileUtils

  PLUGIN_BASE = "/tmp/plugins"

  let(:pm) { CursedConsole::PluginManager.new(PLUGIN_BASE) }
  let(:pm_bad_path) { CursedConsole::PluginManager.new("/tmp/junjun") }

  before(:each) do
    # Create Plugin 1
    mkdir_p File.join(PLUGIN_BASE, "plugin1")
    # Create Resource 1
    File.open(File.join(PLUGIN_BASE, "plugin1", "resource1.rb"), "w") do |f|
      f.write <<-EOF
      module Plugins
        module Plugin1
          class Resource1 < CursedConsole::BaseResource
            def action1
            end
            def action2
            end
            private
            def private_method
            end
          end
        end
      end
      EOF
    end
    # Create Plugin 1
    mkdir_p File.join(PLUGIN_BASE, "plugin2")
    # Create Resource 1
    File.open(File.join(PLUGIN_BASE, "plugin2", "resource2.rb"), "w") do |f|
      f.write <<-EOF
      module Plugins
        module Plugin2
          class Resource2 < CursedConsole::BaseResource
            def action1
            end
            private
            def private_method
            end
          end
        end
      end
      EOF
    end
  end

  after(:each) do
    rm_rf PLUGIN_BASE
  end

  context '#identify_plugins' do

    it "returns the list of plugin names" do
      expect(pm.send(:identify_plugins)).to eq(["plugin1", "plugin2"])
    end

    it "raises an exception if initialized with a bad plugin path" do
      expect(pm_bad_path.send(:identify_plugins)).to eq([])
    end

  end

  context '#plugins' do

    it "returns the list of plugins doing the work only once" do
      expect(pm).to receive(:identify_plugins).
        exactly(1).times.
        and_return([ 'a' ])

      expect(pm.plugins).to eq(['a'])
      # Call a second time to verify we do the work only once
      expect(pm.plugins).to eq(['a'])
    end

  end

  context '#is_valid_plugin_path?' do

    it "returns true when path has good stuff in it" do
      expect(pm.is_valid_plugin_path?).to eq(true)
    end

  end

  context '#resource_modules' do

    it "returns the list of all the resource modules in the plugin path" do
      expect(pm.send(:resource_modules)).
        to eq([File.join(PLUGIN_BASE, "plugin1", "resource1.rb"), 
               File.join(PLUGIN_BASE, "plugin2", "resource2.rb")])
    end

  end

  context '#load_resources' do

    it "raises an exception if the plugin path has no stuff" do
      expect{pm_bad_path.load_resources}.to raise_error
    end

  end

  context '#resources_for' do

    it "returns the resources for the specified plugin" do
      expect(pm.resources_for('plugin2')).to eq([ 'resource2' ])
    end

  end

  context '#actions_for' do

    it "returns the list of actions for the specified resource" do
      pm.load_resources
      expect(pm.actions_for('plugin1', 'resource1')).
        to eq(['action1', 'action2'])
    end

  end

  context '#instantiate_resource' do

    it "should create an instance of the specified resource" do
      pm.load_resources
      expect(pm.instantiate_resource('plugin2', 'resource2')).
        to be_a(Plugins::Plugin2::Resource2)
    end

  end

  context '#resource_class_name' do

    it "returns a constant name for the specifie plugin/resource" do
      pm.load_resources
      expect(pm.send(:resource_class_name, "plugin1", "resource1")).to eq(Plugins::Plugin1::Resource1)
    end
  end

end
