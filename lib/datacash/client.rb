module Datacash
  class Client

    ENDPOINTS = {
      live: "https://mars.transaction.datacash.com/Transaction",
      test: "https://accreditation.datacash.com/Transaction/cnp_a"
    }.freeze

    def initialize(options={})
      @client      = options.fetch(:client, Datacash.configuration.client)
      @password    = options.fetch(:password, Datacash.configuration.password)
      @environment    = options.fetch(:environment, Datacash.configuration.environment)
      @rest_client = options.fetch(:rest_client, RestClient)
    end

    def post(request)
      prepare_request(request)

      handle_response(
        rest_client.post(endpoint, request.to_xml, :content_type => :xml, :accept => :xml)
      )
    rescue RestClient::ResourceNotFound, SocketError, Errno::ECONNREFUSED => e
      raise Datacash::ConnectionError.new(e)
    end

    def query(datacash_reference)
      request = Request::Request.new(transaction: {
        historic_transaction: { 
          method: "query", reference: datacash_reference
        }
      })
      post(request)
    end

    private
    attr_reader :rest_client, :environment, :client, :password

    def parse_response_to_hash(response)
      MultiXml.parse(response, :symbolize_keys => true)[:Response]
    end

    def endpoint
      ENDPOINTS[environment]
    end

    def prepare_request(request)
      request.add_authentication(client: client, password: password)
    end

    def handle_response(raw_response)
      parsed_xml_response = parse_response_to_hash(raw_response)

      if raw_response.blank? || parsed_xml_response.blank?
        raise Datacash::ResponseError.new("Response was empty: #{raw_response}")
      end

      response = Response::Response.new(parsed_xml_response)
      response.raw = raw_response
      if response.reason =~ /invalid client\/pass/i
        raise AuthenticationError, response
      end
      response
    end
  end
end
