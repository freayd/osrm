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

  def self.routes(*locations, overview: nil)
    Query.new(*locations).execute(overview: overview)
  end

  def self.route(*locations, overview: nil)
    Query.new(*locations).execute(overview: overview).first
  end
end
