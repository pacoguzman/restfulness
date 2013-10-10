require 'uri'
require 'cgi'
require 'active_support/hash_with_indifferent_access'

module Restfulness

  # Simple, indpendent, request interface for dealing with the incoming information
  # in a request. 
  #
  # Currently wraps around the information provided in a Rack Request object.
  class Request

    # Who does this request belong to?
    attr_reader :app

    # The HTTP action being handled
    attr_accessor :action

    # Hash of HTTP headers. Keys always normalized to lower-case symbols with underscore.
    attr_accessor :headers

    # Ruby URI object
    attr_reader :uri

    # Path object of the current URL being accessed
    attr_accessor :path

    # The route, determined from the path, if available!
    attr_accessor :route

    # Query parameters included in the URL
    attr_accessor :query

    # Raw HTTP body, for POST and PUT requests.
    attr_accessor :body

    def initialize(app)
      self.app = app

      # Prepare basics
      self.action  = nil
      self.headers = {}
      self.body    = nil
    end

    def uri=(uri)
      @uri = URI(uri)
    end

    def path
      @path ||= (route ? route.build_path(uri.path) : nil)
    end

    def route
      # Determine the route from the uri
      @route ||= app.router.route_for(uri)
    end

    def query
      @query ||= ActiveSupport::HashWithIndifferentAccess.new(
        CGI::parse(uri.query)
      )
    end

    def params
      return @params if @params || body.nil?
      case headers[:content_type]
      when 'application/json'
        @params = JSON.parse(body)
      else
        raise HTTPException.new(406)
      end
    end

  end
end