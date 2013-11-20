module Tempest

  require 'httparty'
  require 'json'
  require 'uri'
  require 'promise'

  class Stingray 
    include HTTParty

    attr_reader :auth, :uri

    headers 'Accept' => 'application/json'
    headers 'Content-Type' => 'application/json'
    format :json
    default_options.merge! verify: false

    # Create an instance
    def initialize ( uri, username, password ) 
      @auth = { username: username, password: password }
      @uri = uri  
    end

    def protocol_version
      '1.0'
    end
    
    # Returns an Array of strings represting the pools configured on the Traffic Manager
    def pools
      res = Hash.new
      Pool.all(self).each { |x| res[x]=promise { Pool.new(self,x) } }
      res
    end
    
    def vservers
      res = Hash.new
      Vserver.all(self).each { |x| res[x] = promise { Vserver.new(self,x) } }
      res
    end
    
    def traffic_ips
      res = Hash.new
      TrafficIP.all(self).each { |x| res[x] = promise { TrafficIP.new(self,x) } }
      res
    end
    
    class Generic
      attr_reader :name, :raw_data

      def initialize (parent, name=nil)
        @parent=parent
        if name
          @name=name
          # Handle missing name here. TODO
          @raw_data=get
        end
      end
            
      # Return a list of all Pools for a given Stingray object
      def self.all sr
        response = sr.class.get URI.escape("#{sr.uri}/api/tm/#{sr.protocol_version}/#{self.path}"), {basic_auth: sr.auth}
        raise response["error_text"] unless response.code == 200
        response.parsed_response["children"].map {|x| x["name"]}
      end

      private

      def get
        response = @parent.class.get URI.escape("#{@parent.uri}/api/tm/#{@parent.protocol_version}/#{self.class.path}/#{@name}"), {basic_auth: @parent.auth}
        raise response["error_text"] unless response.code == 200
        response.parsed_response
      end

      def put
        response = @parent.class.put("#{@parent.uri}/api/tm/#{@parent.protocol_version}/#{self.class.path}/#{name}", {basic_auth: @parent.auth, body: @raw_data.to_json})
        raise response["error_text"] unless response.code == 200
        response.parsed_response
      end
      
    end

    class Pool < Generic
      attr_reader :name
      
      # Returns an array of draining nodes
      def draining_nodes
        @raw_data["properties"]["basic"]["draining"]
      end
      
      # Returns an Array of enabled nodes
      def enabled_nodes
        @raw_data["properties"]["basic"]["nodes"].reject(){|x| draining_nodes.include? x }        
      end
      
      # Returns an Array of disabled nodes
      def disabled_nodes
        @raw_data["properties"]["basic"]["disabled"]
      end
      
      # Returns an Array of node names
      def nodes
        ( enabled_nodes | disabled_nodes | draining_nodes )
      end

      # Return true if a node is in the pool
      def has_node? node
          nodes.include? node
      end
      
      # Returns true if a node is marked as disabled
      def node_is_disabled? node
        @raw_data["properties"]["basic"]["disabled"].include? node
      end
      
      # Returns true if a node is marked as draining
      def node_is_draining? node
        @raw_data["properties"]["basic"]["draining"].include? node
      end
      
      # Enable a node
      def enable_node node
        raise "Could not find #{node} in #{@name}" unless has_node? node
        @raw_data["properties"]["basic"]["draining"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["disabled"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["nodes"] = @raw_data["properties"]["basic"]["nodes"] | [node]
        put
      end
      
      # Disable a node
      def disable_node node
        raise "Could not find #{node} in #{@name}" unless has_node? node
        @raw_data["properties"]["basic"]["nodes"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["draining"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["disabled"] = @raw_data["properties"]["basic"]["disabled"] | [node]
        put
      end
      
      # Drain a node
      def drain_node node
        raise "Could not find #{node} in #{@name}" unless has_node? node
        @raw_data["properties"]["basic"]["draining"] = @raw_data["properties"]["basic"]["draining"] | [node]
        put
      end

      private

      def self.path
        "config/active/pools"
      end
    end
    
    class Vserver < Generic
      
      def default_pool
        @raw_data["properties"]["basic"]["pool"]
      end
      
      def port
        @raw_data["properties"]["basic"]["port"]
      end
      
      def protocol
        @raw_data["properties"]["basic"]["protocol"]
      end
      
      def enabled?
        @raw_data["properties"]["basic"]["enabled"]
      end
      
      def enable
        @raw_data["properties"]["basic"]["enabled"]=true
        put
      end
      
      def disable
        @raw_data["properties"]["basic"]["enabled"]=false
        put
      end
      
      def listen_on_traffic_ips
        @raw_data["properties"]["basic"]["listen_on_traffic_ips"]
      end
      
      private
      
      def self.path
        "config/active/vservers"
      end
    end
    
    class TrafficIP < Generic
      
      def enabled?
        @raw_data["properties"]["basic"]["enabled"]
      end
      
      def enable
        @raw_data["properties"]["basic"]["enabled"]=true
        put
      end
      
      def disable
        @raw_data["properties"]["basic"]["enabled"]=false
        put
      end
      
      def ip_addresses
        @rawdata["properties"]["basic"]["ipaddresses"]
      end
      
      private
      
      def self.path
        "config/active/flipper"
      end
      
    end
    
  end

end