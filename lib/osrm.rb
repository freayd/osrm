require 'osrm/configuration'
require 'osrm/query'
require 'osrm/route'
require 'osrm/version'

module OSRM
  def self.configure(options)
    Configuration.instance.merge!(options)
  end

  def self.configuration
    Configuration.instance
  end

  def self.routes(*locations)
    OSRM::Query.new(*locations).execute
  end

  def self.route(*locations)
    routes(*locations).first
  end
end
