require 'yaml'
require 'json'
require 'fileutils'
require 'chef-api'

module ChefProvisioner
  # Simple API to access chef server to manage clients and nodes
  module Chef
    extend self

    def configure(**kwargs)
      ChefAPI.configure do |config|
        config.endpoint = kwargs[:endpoint]
        config.client = kwargs[:client]
        config.key = kwargs[:key_text] || File.read(kwargs[:key_path])
      end
    end

    def init_server(name, environment: '_default', attributes:{}, run_list:[], force: false)
      nuke(name) if force
      key = create_client(name)
      create_node(name, environment, key, attributes: attributes, run_list: run_list)
      key
    end

    def create_client(name)
      client = ChefAPI::Connection.new.clients.create(name: name)
      client.private_key
    rescue => e
      puts "Failed to create client #{name}"
      puts e.message
    end

    def create_node(name, environment, key, attributes:{}, run_list:[])
      client_connection = ChefAPI::Connection.new do |connection|
        connection.key = key
      end
      node = client_connection.nodes.create(name: name, run_list: run_list)
      node.chef_environment = environment
      node.automatic = attributes['automatic'] || {}
      node.default = attributes['default'] || {}
      node.normal = attributes['normal'] || {}
      node.override = attributes['override'] || {}
      node.save
    rescue => e
      puts "Failed to create node #{name}"
      puts e.message
    end

    def delete_client(name)
      ChefAPI::Connection.new.clients.destroy(name)
    rescue => e
      puts "Failed to delete client #{name}"
      puts e.message
    end

    def delete_node(name)
      ChefAPI::Connection.new.nodes.destroy(name)
    rescue => e
      puts "Failed to delete node #{name}"
      puts e.message
    end

    def nuke(name)
      delete_client(name)
      delete_node(name)
    end
  end
end
