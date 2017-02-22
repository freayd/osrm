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

  def self.routes(*locations, overview: nil, profile: nil)
    Query.new(*locations)
         .execute(alternatives: true, overview: overview, profile: profile)
  end

  def self.route(*locations, overview: nil, profile: nil)
    Query.new(*locations)
         .execute(alternatives: false, overview: overview, profile: profile)
         .first
  end

  def self.method_missing(method, *arguments, **keyword_arguments)
    if /^(?<delegate>routes?)_by_(?<profile>[a-z]+)$/ =~ method
      keyword_arguments[:profile] = profile
      method(delegate).call(*arguments, **keyword_arguments)
    else
      super
    end
  end

  def self.respond_to_missing?(method, *)
    /^routes?_by_[a-z]+$/.match(method) || super
  end
end
