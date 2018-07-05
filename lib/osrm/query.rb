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

    def execute(alternatives: nil, overview: nil, profile: nil)
      build_uri(alternatives: alternatives, overview: overview, profile: profile)
      fetch_json_data[:routes].map { |route| Route.new(route) }
    end

    private

    def fetch_json_data
      raw_data = cache || fetch_raw_data

      json = JSON.parse(raw_data, symbolize_names: true)
      raise "OSRM API error: #{json[:message]}#{' ('+json[:code]+')' if json[:code]}" unless json[:code] == 'Ok'

      cache(raw_data)
      json
    rescue JSON::ParserError => error
      raise "OSRM API error: Invalid JSON: (#{error})"
    end

    def fetch_raw_data
      configuration.before_request.call if configuration.before_request
      response = api_request
      configuration.after_request.call if configuration.after_request

      ensure_valid_response(response)
      response.body
    rescue SocketError
      raise 'OSRM API error: Unable to establish connection'
    rescue SystemCallError => error
      # NOTE: Identify error class by string in case the class
      #   is not implemented on the current platform
      case error.class.to_s
      when 'Errno::EHOSTDOWN'
        raise 'OSRM API error: Host is down'
      when 'Errno::ECONNREFUSED'
        raise 'OSRM API error: Connection refused'
      else
        raise
      end
    rescue Timeout::Error
      raise 'OSRM API error: Timeout expired'
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

    def ensure_valid_response(response)
      return if %w(200 400).include?(response.code)

      begin
        return if response.body.start_with?('{') && JSON.parse(response.body)
      rescue JSON::ParserError
        nil
      end

      if configuration.use_demo_server? &&
         response['location']&.include?('forbidden.html')
        raise 'OSRM API error: API usage policy has been violated, see https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy'
      end

      ensure_ready_server if response.code == '404'
      raise "OSRM API error: Invalid response #{response.code} #{response.message}"
    end

    def ensure_ready_server
      root_uri = @uri.class.build(host: @uri.host, port: @uri.port)
      root_response = Net::HTTP.get(root_uri)
      raise "OSRM API error: #{root_response}" if root_response.match(/NOT READY/i)
    end

    def build_uri(alternatives: nil, overview: nil, profile: nil)
      raise "OSRM API error: Server isn't configured" unless configuration.server

      use_mapbox = configuration.use_mapbox_server?
      service = use_mapbox ? 'directions' : 'route'
      version = use_mapbox ? 'v5' : 'v1'
      profile ||= 'driving'
      profile = 'mapbox/' + profile if use_mapbox # NOTE: Do NOT use prepend which modifies the source parameter
      format  = 'json'

      alternatives = alternatives.nil? ? false : (alternatives == true)
      if overview.nil?
        overview = configuration.overview
      else
        configuration.ensure_valid_overview(overview)
      end

      params = [
        ['alternatives', alternatives.to_s],
        ['geometries', 'polyline'],
        ['overview', overview.to_s]
      ]

      params << ['access_token', configuration.api_key] if use_mapbox

      uri_class = configuration.use_ssl? ? URI::HTTPS : URI::HTTP
      @uri = uri_class.build(
        host: configuration.server,
        port: configuration.port,
        path: "#{configuration.path_prefix}/#{service}/#{version}/#{profile}/#{lonlat_locations.join(';')}.#{format}",
        query: URI.encode_www_form(params)
      )
    end

    # Reverse from ['latitude,longitude'] to ['longitude,latitude']
    def lonlat_locations
      locations.map { |location| location.split(',').reverse.join(',') }
    end

    def cache(value = nil)
      return nil unless configuration.cache

      if value
        configuration.cache[configuration.cache_key('version')] ||= OSRM::VERSION
        configuration.cache[configuration.cache_key(@uri.to_s)] = value
      else
        configuration.cache[configuration.cache_key(@uri.to_s)]
      end
    end

    def configuration
      OSRM.configuration
    end
  end
end
