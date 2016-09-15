require 'json'
require 'net/http'
require 'timeout'
require 'uri'

module OSRM
  class Query
    attr_accessor :locations

    def initialize(*locations)
      @locations = locations.compact.reject(&:empty?)
    end

    def execute
      build_uri
      json = fetch_json_data
      routes = []
      return routes if json.nil?

      # Main route
      routes << Route.new(
        geometry: json['route_geometry'],
        summary:  json['route_summary']
      )

      # Alternative routes
      if json['found_alternative']
        json['alternative_geometries'].each_index do |index|
          routes << Route.new(
            geometry: json['alternative_geometries'][index],
            summary:  json['alternative_summaries'][index]
          )
        end
      end

      routes
    end

    private

    def fetch_json_data
      raw_data = cache || fetch_raw_data

      json = JSON.parse(raw_data) if raw_data

      cache(raw_data)
      json
    rescue JSON::ParserError => error
      warn "OSRM API error: Invalid JSON: (#{error})"
    end

    def fetch_raw_data
      configuration.before_request.call if configuration.before_request
      response = api_request
      configuration.after_request.call if configuration.after_request

      response.body if valid_response?(response)
    rescue SocketError
      warn 'OSRM API error: Unable to establish connection'
    rescue SystemCallError => error
      # NOTE: Identify error class by string in case the class
      #   is not implemented on the current platform
      case error.class.to_s
      when 'Errno::EHOSTDOWN'
        warn 'OSRM API error: Host is down'
      when 'Errno::ECONNREFUSED'
        warn 'OSRM API error: Connection refused'
      else
        raise
      end
    rescue Timeout::Error
      warn 'OSRM API error: Timeout expired'
    end

    def api_request
      Timeout.timeout(configuration.timeout) do
        Net::HTTP.start(@uri.host, @uri.port,
                        use_ssl: configuration.use_ssl?) do |http|
          response = http.get(
            @uri.request_uri,
            'User-Agent' => configuration.user_agent
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

      if configuration.use_demo_server? &&
         response['location'] &&
         response['location']['forbidden.html']
        warn 'OSRM API error: API usage policy has been violated, see https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy'
      else
        warn 'OSRM API error: Invalid response' \
             " #{response.code} #{response.message}"
      end

      false
    end

    def build_uri
      raise "OSRM API error: Server isn't configured" unless configuration.server

      service  = 'viaroute'
      params = [
        *@locations.map { |l| ['loc', l] },
        %w(output json),
        %w(instructions false),
        %w(alt true)
      ]

      uri_class = configuration.use_ssl? ? URI::HTTPS : URI::HTTP
      @uri = uri_class.build(
        host: configuration.server,
        port: configuration.port,
        path: "/#{service}",
        query: URI.encode_www_form(params)
      )
    end


    def cache(value = nil)
      return nil unless configuration.cache

      if value
        configuration.cache[cache_key('version')] ||= OSRM::VERSION
        configuration.cache[cache_key(@uri.to_s)] = value
      else
        configuration.cache[cache_key(@uri.to_s)]
      end
    end

    def cache_key(url)
      configuration.cache_key.gsub('{url}', url)
    end

    def configuration
      OSRM.configuration
    end
  end
end
