module Weary
  class Request
    
    attr_reader :uri
    attr_accessor :options, :credentials, :with
  
    def initialize(url, http_verb= :get, options={})
      self.method = http_verb
      self.uri = url
      self.options = options
      self.credentials = {:username => options[:basic_auth][:username], 
                          :password => options[:basic_auth][:password]} if options[:basic_auth]
      self.credentials = options[:oauth] if options[:oauth]
      if (options[:body])
        self.with = (options[:body].respond_to?(:to_params) ? options[:body].to_params : options[:body])
      end
    end
  
    def uri=(url)
      @uri = URI.parse(url)
    end
    
    def method=(http_verb)
      verb = HTTPVerb.new(http_verb).normalize
      @http_verb = if Methods.include?(verb)
        verb
      else
        :get
      end
    end
    
    def method
      @http_verb
    end
    
    def perform
      req = http.request(request)
      response = Response.new(req, @http_verb)
      if response.redirected?
        return response if options[:no_follow]
        response.follow_redirect
      end
      response
    end
    
    private
      def http
        connection = Net::HTTP.new(@uri.host, @uri.port)
        connection.use_ssl = @uri.is_a?(URI::HTTPS)
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl
        connection
      end
    
      def request
        request_class = HTTPVerb.new(@http_verb).request_class        
        prepare = request_class.new(@uri.request_uri)
        
        prepare.body = options[:body].is_a?(Hash) ? options[:body].to_params : options[:body] if options[:body]
        prepare.basic_auth(options[:basic_auth][:username], options[:basic_auth][:password]) if options[:basic_auth]
        if options[:headers]
          options[:headers].each_pair do |key, value|
            prepare[key] = value
          end
        end
        if options[:oauth]
          options[:oauth].sign!(prepare)
        end
        prepare
      end

  end
end