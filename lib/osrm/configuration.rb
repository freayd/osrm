require 'singleton'

module OSRM
  class Configuration
    include Singleton

    DEFAULTS = {
      server:  nil,
      port:    nil,
      use_ssl: false
    }.freeze

    DEMO_SERVER = 'router.project-osrm.org'.freeze

    def initialize
      @data = DEFAULTS.dup
    end

    def merge!(options)
      options.each do |option, value|
        public_send(:"#{option}=", value) if DEFAULTS.key?(option.to_sym)
      end

      self
    end

    def server=(server)
      @data[:server] =
        server == :demo ? Configuration::DEMO_SERVER.dup : server
    end

    def port=(port)
      @data[:port] = port && port.to_i
    end

    def use_ssl=(use_ssl)
      @data[:use_ssl] = use_ssl ? true : false
    end

    def use_demo_server?
      @data[:server] == DEMO_SERVER
    end

    # Dynamically add missing accessors
    DEFAULTS.each do |option, default_value|
      reader = case default_value
               when TrueClass, FalseClass then :"#{option}?"
               else option
               end
      writer = :"#{option}="

      define_method(reader) { @data[option] }
      unless method_defined?(writer)
        define_method(writer) { |value| @data[option] = value }
      end
    end
  end
end
