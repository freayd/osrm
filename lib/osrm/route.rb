require 'encoded_polyline'

module OSRM
  class Route
    attr_accessor :geometry, :distance, :duration

    def initialize(json = {})
      @geometry = decode_geometry(json[:geometry])
      @distance = json[:distance].to_f
      @duration = json[:duration].to_f
    end

    private

    def decode_geometry(geometry)
      return [] if geometry.nil? || geometry.empty?

      EncodedPolyline.decode_points(geometry, 5).map do |point|
        point.map { |coordinate| fix_float_precision(coordinate) }
      end
    end

    # HACK: Should fix encoded_polyline gem instead
    def fix_float_precision(float)
      decimals = float.to_f.to_s[/\d+\z/]
      fixed_decimals = decimals.sub(/(\d)\1{5,}\d{,2}\z/, '')

      decimals == fixed_decimals ? float : float.round(fixed_decimals.size)
    end
  end
end
