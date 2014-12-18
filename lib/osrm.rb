require 'osrm/configuration'
require 'osrm/query'
require 'osrm/route'
require 'osrm/version'

module OSRM
  def self.routes(*locations)
    OSRM::Query.new(*locations).execute
  end

  def self.route(*locations)
    routes(*locations).first
  end
end
