require 'singleton'

module OSRM
  def self.configure(options)
    if options[:server] == :demo
      options.merge!(
        server: Configuration::DEMO_SERVER.dup,
        port:   nil
      )
    end

    Configuration.instance.merge!(options)
  end

  def self.configuration
    Configuration.instance
  end

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
      @data.merge!(options)
      self
    end

    def use_demo_server?
      @data[:server] == DEMO_SERVER
    end

    def port
      @data[:port] && @data[:port].to_i
    end

    def use_ssl?
      @data[:use_ssl]
    end

    # Dynamically add missing accessors
    DEFAULTS.each_key do |key|
      define_method(key) { @data[key] } unless method_defined?(key)
      define_method(:"#{key}=") { |value| @data[key] = value }
    end
  end
end
