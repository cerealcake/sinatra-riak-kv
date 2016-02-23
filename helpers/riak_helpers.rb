module RiakHelpers

  def search(index,key,value,page,per_page)
    search_results=Array.new
    start = (per_page.to_i)*(page.to_i - 1)

    SETTINGS.riaknode.each { |node|
      client = Riak::Client.new( :host => node[:name], :pb_port => '8087')
      riak_search = client.search(index, "#{key}:#{value}", {:start => start.to_i, :rows => per_page.to_i})
      riak_search["riak_node"]=node[:name]
      search_results << riak_search
    }
    search_results
  rescue Riak::ProtobuffsErrorResponse
    nil
  rescue Riak::ProtobuffsFailedRequest
    nil
  end

  def keys(bucket_type,bucket,key)
    search_results = Array.new

    SETTINGS.riaknode.each { |node|
      begin
        client = Riak::Client.new( :host => node[:name], :pb_port => '8087')
        riak_search = client.bucket_type("#{bucket_type}").bucket("#{bucket}").get("#{key}")
        riak_search.data["riak_node"]=node[:name]
        search_results << riak_search.data
      rescue Riak::ProtobuffsErrorResponse
        nil
      rescue Riak::ProtobuffsFailedRequest  
        nil
      end
    }
    search_results
 
  end

end
