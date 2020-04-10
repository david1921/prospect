module Services
    class Gcse
        HOST = "https://www.googleapis.com"
        SEARCH_PATH = '/customsearch/v1'

      def self.search query
        # request =Gcse.new.get_request(SEARCH_PATH, GOOGLE_CSE_KEY, {:cx=> CX,:q=> query})
        # puts request
        puts query
      end

      #  def get_request path, key, options
      #      client.get do |req|
      #        req.url  path 
      #        req.params['key'] = key 

      #        #for GCSE"
      #        req.params['q'] = options[:q] if options[:q] 
      #        req.params['cx'] = options[:cx] if options[:cx] 
      #      end
      # end

      # #private
      #  def client
      #    Faraday.new(url: HOST) do |faraday|
      #     faraday.response :logger
      #     faraday.adapter Faraday.default_adapter
      #    # faraday.headers['Authorization'] = key if key
      #     #faraday.headers['Accept'] = 'application/json'
      #   end
      #  end

      
    end
end