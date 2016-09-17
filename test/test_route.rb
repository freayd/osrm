require 'helper'

class TestRoute < Minitest::Test
  def test_empty_route
    [
      OSRM::Route.new,
      OSRM::Route.new(geometry: nil),
      OSRM::Route.new(geometry: '')
    ].each do |route|
      assert_equal [], route.geometry
    end
  end

  def test_geometry
    [
      [
        [[3.85, -12.02], [4.07, -12.095], [4.3252, -12.6453]],
        'o}nV~sjhA_~i@vsM_zp@jnjB'
      ],
      [
        [[21, 78], [-3.07583, 37.35333], [72, -40], [-13.16333, -72.54556]],
        '_qd_C_ka{M|h}qCtxawF}ffiMhacwMxmxfOvpseE'
      ],
      [
        [[0, 0]],
        '??'
      ]
    ].each do |decoded, encoded|
      assert_equal decoded,
                   OSRM::Route.new(geometry: encoded).geometry
    end
  end

  def test_float_precision
    route = OSRM::Route.new

    [
      [ 123,      123    ],
      [-123,     -123    ],
      [ 123.456,  123.456],
      [123_000_000_000_000, 123_000_000_000_000],
      [0.123456789123456789, 0.123456789123456789],
      [ 0.1,  0.14444444444412],
      [ 0.2,  0.15555555555512],
      [-0.2, -0.19999999999912],
      [12.124,        12.123999999945],
      [12.124,        12.12399999945 ],
      [12.1239999945, 12.1239999945  ]
    ].each do |fixed_float, float|
      assert_equal fixed_float, route.send(:fix_float_precision, float)
    end
  end
end
