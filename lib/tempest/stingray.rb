require 'httparty'
require 'json'

class Stingray 
  include HTTParty

  headers 'Accept' => 'application/json'
  headers 'Content-Type' => 'application/json'
  format :json
  default_options.merge! verify: false

  def initialize ( uri, username, password ) 
    @auth = { username: username, password: password }
    @uri = uri  
  end
  
  def get_pool (name)
    response = self.class.get("#{@uri}/api/tm/1.0/config/active/pools/#{name}", {basic_auth: @auth})
    raise response["error_text"] unless response.code == 200
    response.parsed_response
  end
  
  def put_pool (name, obj) 
    response = self.class.put("#{@uri}/api/tm/1.0/config/active/pools/#{name}", {basic_auth: @auth, body: obj.to_json})
    raise response["error_text"] unless response.code == 200
    response.parsed_response
  end
  
  def get_nodes (pool)
    p=get_pool pool
    p["properties"]["basic"]["nodes"]
  end

  def drain_node (node, pool)
    p = get_pool pool
    nodes = p["properties"]["basic"]["nodes"]
    raise "#{node} found in #{pool}" unless nodes.include? node
    p["properties"]["basic"]["draining"] = p["properties"]["basic"]["draining"] | [node]
    put_pool pool, p
  end
  
  def node_is_disabled? node, pool
    p = get_pool pool
    p["properties"]["basic"]["disabled"].include? node
  end
  
  def has_node? node, pool
    p = get_pool pool
    b = p["properties"]["basic"]
    (b["disabled"] | b["nodes"]).include? node
  end
  
  def disable_node (node, pool)
    raise "Could not find #{node} in #{pool}" unless has_node? node, pool
    p = get_pool pool
    p["properties"]["basic"]["nodes"].reject! {|x| x == node}
    p["properties"]["basic"]["draining"].reject! {|x| x == node}
    p["properties"]["basic"]["disabled"]=p["properties"]["basic"]["disabled"] | [node]
    put_pool pool, p
  end
  
  def enable_node (node, pool)
    p = get_pool pool
    p["properties"]["basic"]["draining"].reject! {|x| x == node}
    p["properties"]["basic"]["disabled"].reject! {|x| x == node}
    p["properties"]["basic"]["nodes"]=p["properties"]["basic"]["nodes"] | [node]
    put_pool pool, p
  end
end
