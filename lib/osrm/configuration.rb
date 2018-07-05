require 'singleton'
require 'osrm/version'

module OSRM
  class Configuration
    include Singleton

    DEFAULTS = {
      server:  nil,
      port:    nil,
      use_ssl: false,
      api_key: nil,
      path_prefix: '',

      timeout:        3,
      user_agent:     "OSRMRubyGem/#{OSRM::VERSION}",
      before_request: nil,
      after_request:  nil,

      cache:     nil,
      cache_key: 'osrm:{url}',

      overview:  :simplified
    }.freeze

    DEMO_SERVER   = 'router.project-osrm.org'.freeze
    MAPBOX_SERVER = 'api.mapbox.com'.freeze

    def initialize
      @data = {}
      merge!(DEFAULTS.dup)
    end

    def merge!(options)
      options.each do |option, value|
        public_send(:"#{option}=", value) if DEFAULTS.key?(option.to_sym)
      end

      self
    end

    def server=(server)
      @data[:server] =
        case server
        when :demo, DEMO_SERVER
          DEMO_SERVER.dup
        when :mapbox, MAPBOX_SERVER
          self.use_ssl = true
          MAPBOX_SERVER.dup
        else
          server
        end
    end

    def use_demo_server?
      @data[:server] == DEMO_SERVER
    end

    def use_mapbox_server?
      @data[:server] == MAPBOX_SERVER
    end

    def port=(port)
      @data[:port] = port&.to_i
    end

    def use_ssl=(use_ssl)
      @data[:use_ssl] = use_ssl ? true : false
    end

    def path_prefix=(path_prefix)
      unless path_prefix.empty? || path_prefix.match?(/\A\/.*[^\/]\z/)
        raise "OSRM API error: Invalid path prefix #{path_prefix.inspect}"
      end

      @data[:path_prefix] = path_prefix
    end

    def timeout=(timeout)
      @data[:timeout] = timeout&.to_i
    end

    def before_request=(before_request)
      if before_request && !before_request.is_a?(Proc)
        raise "OSRM API error: Invalid before request #{before_request.inspect}"
      end

      @data[:before_request] = before_request
    end

    def after_request=(after_request)
      if after_request && !after_request.is_a?(Proc)
        raise "OSRM API error: Invalid after request #{after_request.inspect}"
      end

      @data[:after_request] = after_request
    end

    def cache=(cache)
      @data[:cache] = cache
      ensure_cache_version
    end

    # Raise an exception if the cache isn't compatible with the current library version
    def ensure_cache_version
      return unless cache

      cache_version = cache[cache_key('version')]
      minimum_version = '0.4.0'
      if cache_version &&
         Gem::Version.new(cache_version) < Gem::Version.new(minimum_version)
        @data[:cache] = nil
        raise "OSRM API error: Incompatible cache version #{cache_version}, " +
              "expected #{minimum_version} or higher"
      end
    end

    def cache_key(url = nil)
      if url
        @data[:cache_key]&.gsub('{url}', url)
      else
        @data[:cache_key]
      end
    end

    def cache_key=(cache_key)
      unless cache_key.include?('{url}')
        raise "OSRM API error: Invalid cache key #{cache_key.inspect}"
      end

      @data[:cache_key] = cache_key
      ensure_cache_version
    end

    def overview=(overview)
      ensure_valid_overview(overview)
      @data[:overview] = overview
    end

    def ensure_valid_overview(overview)
      unless [false, :simplified, :full].include?(overview)
        raise "OSRM API error: Invalid overview type #{overview.inspect}"
      end
    end

    # Dynamically add missing accessors
    DEFAULTS.each do |option, default_value|
      reader = case default_value
               when TrueClass, FalseClass then :"#{option}?"
               else option
               end
      writer = :"#{option}="

      unless method_defined?(reader)
        define_method(reader) { @data[option] }
      end
      unless method_defined?(writer)
        define_method(writer) { |value| @data[option] = value }
      end
    end
  end
end
