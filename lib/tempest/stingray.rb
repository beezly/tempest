module Tempest

  require 'httparty'
  require 'json'

  class Stingray 
    include HTTParty

    attr_reader :auth, :uri

    headers 'Accept' => 'application/json'
    headers 'Content-Type' => 'application/json'
    format :json
    default_options.merge! verify: false

    def initialize ( uri, username, password ) 
      @auth = { username: username, password: password }
      @uri = uri  
    end

    def protocol_version
      '1.0'
    end

    class Generic
      attr_reader :raw_data

      def initialize(parent)
        @parent=parent
      end
    end

    class Pool < Generic
      attr_reader :name

      def initialize (parent, name=nil)
        super(parent)
        if name
          @name=name
          @raw_data=get
        end
      end
      
      def refresh
        get
      end
      
      def draining_nodes
        @raw_data["properties"]["basic"]["draining"]
      end
      
      def enabled_nodes
        @raw_data["properties"]["basic"]["nodes"].reject(){|x| draining_nodes.include? x }        
      end
      
      def disabled_nodes
        @raw_data["properties"]["basic"]["disabled"]
      end
      
      def nodes
        ( @raw_data["properties"]["basic"]["nodes"] | @raw_properties["properties"]["basic"]["disabled"] )
      end

      def has_node? node
          b = @raw_data["properties"]["basic"]
          (b["disabled"] | b["nodes"]).include? node
      end
      
      def node_is_disabled? node
        @raw_data["properties"]["basic"]["disabled"].include? node
      end
      
      def node_is_draining? node
        @raw_data["properties"]["basic"]["draining"].include? node
      end
      
      def enable_node node
        raise "Could not find #{node} in #{@name}" unless has_node? node
        @raw_data["properties"]["basic"]["draining"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["disabled"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["nodes"] = @raw_data["properties"]["basic"]["nodes"] | [node]
        put
      end
      
      def disable_node node
        raise "Could not find #{node} in #{@name}" unless has_node? node
        @raw_data["properties"]["basic"]["nodes"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["draining"].reject! {|x| x == node}
        @raw_data["properties"]["basic"]["disabled"] = @raw_data["properties"]["basic"]["disabled"] | [node]
        put
      end
      
      def drain_node node
        raise "Could not find #{node} in #{@name}" unless has_node? node
        @raw_data["properties"]["basic"]["draining"] = @raw_data["properties"]["basic"]["draining"] | [node]
        put
      end

      private

      def get
        response = @parent.class.get "#{@parent.uri}/api/tm/#{@parent.protocol_version}/config/active/pools/#{@name}", {basic_auth: @parent.auth}
        raise response["error_text"] unless response.code == 200
        response.parsed_response
      end

      def put
        response = @parent.class.put("#{@parent.uri}/api/tm/#{@parent.protocol_version}/config/active/pools/#{name}", {basic_auth: @parent.auth, body: @raw_data.to_json})
        raise response["error_text"] unless response.code == 200
        response.parsed_response
      end
    end
    
  end

end