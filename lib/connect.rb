require 'nokogiri'
module Connect
  class Connection
    def self.api host, key=nil
      Faraday.new(url: host) do |faraday|
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.headers['Authorization'] = key if key
        #faraday.headers['Accept'] = 'application/json'
      end
    end
  end

  class Request   
       def initialize host, path, key = nil, options = {}
         @host = host
         @path = path
         @key = key
         @options = options
       end

       def get
         response = self.get_request
         body = response.body
         JSON.parse(body)
       end
   
       def get_html
         response = self.get_request
         body = response.body
         Nokogiri::HTML(body)
      end

       def get_request 
         conn.get do |req|
           req.url  @path if @path
           req.params['key'] = @key if @key

           req.params['api_key'] = @options[:api_key] if @options[:api_key] 
           req.params['url'] = @options[:url] if @options[:url] 

           #for GCSE"
           req.params['q'] = @options[:q] if @options[:q] 
           req.params['cx'] = @options[:cx] if @options[:cx] 
           
           #Yelp
           req.params['term'] = @options[:term] if @options[:term] 
           req.params['location'] = @options[:location] if @options[:location] 

           #Google Places
           req.params['query'] = @options[:query] if @options[:query] 
           req.params['placeid'] = @options[:place_id] if @options[:place_id] 

           #Foursquare
           req.params['query'] = @options[:four_square_query] if @options[:four_square_query] 
           req.params['near'] = @options[:near] if @options[:near] 
           req.params['client_id'] = @options[:client_id] if @options[:client_id] 
           req.params['client_secret'] = @options[:secret_key] if @options[:secret_key] 
           req.params['v'] = @options[:v] if @options[:v] 

           #Yellow Pages
           req.params['searchloc'] = @options[:yp_location] if @options[:yp_location] 
           req.params['term'] = @options[:yp_term] if @options[:yp_term] 
           req.params['format'] = @options[:formats] if @options[:formats] 
           req.params['listingid'] = @options[:yp_location_id] if @options[:yp_location_id] 
         end
       end

       def conn
        Connection.api(@host,@options[:auth])
       end
  end
end