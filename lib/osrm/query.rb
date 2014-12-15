require 'json'
require 'net/http'
require 'timeout'
require 'uri'

module OSRM
  class Query
    attr_accessor :locations

    def initialize(*locations)
      @locations = locations
    end

    def execute
      fetch_json_data
      # TODO: Convert json to [Route, Route, Route, ...]
    end

    private

    def fetch_json_data
      raw_data = fetch_raw_data
      JSON.parse(raw_data) if raw_data
    rescue JSON::ParserError
      warn 'OSRM API error: Invalid JSON'
    end

    def fetch_raw_data
      response = api_request
      response.body if valid_response?(response)
    rescue SocketError
      warn 'OSRM API error: Unable to establish connection'
    rescue SystemCallError => err
      # NOTE: Identify error class by string in case the class
      #   is not implemented on the current platform
      case err.class.to_s
      when 'Errno::EHOSTDOWN'
        warn 'OSRM API error: Host is down'
      when 'Errno::ECONNREFUSED'
        warn 'OSRM API error: Connection refused'
      else
        raise
      end
    rescue TimeoutError
      warn 'OSRM API error: Timeout expired'
    end

    def api_request
      timeout(3) do
        uri = URI.parse(url)

        Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl?) do |http|
          response = http.get(
            uri.request_uri,
            'User-Agent' => "OSRMRubyGem/#{OSRM::VERSION}"
          )

          if response.class.body_permitted?
            charset = response.type_params['charset']
            response.body.force_encoding(charset) if charset
          end

          response
        end
      end
    end

    def valid_response?(response)
      return true if response.is_a?(Net::HTTPOK)

      if response['location'] && response['location']['forbidden.html']
        warn 'OSRM API error: API usage policy has been violated, see https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy'
      else
        warn 'OSRM API error: Invalid response' \
             " #{response.code} #{response.message}"
      end

      false
    end

    def url
      protocol = "http#{'s' if use_ssl?}"
      host     = 'router.project-osrm.org'
      service  = 'viaroute'
      params = [
        *@locations.map { |l| ['loc', l] },
        %w(output json),
        %w(instructions false),
        %w(alt true)
      ]
      "#{protocol}://#{host}/#{service}?#{URI.encode_www_form(params)}"
    end

    def use_ssl?
      true
    end
  end
end
