require 'helper'

class TestQuery < Minitest::Test
  def test_empty_locations
    [
      OSRM::Query.new,
      OSRM::Query.new(nil),
      OSRM::Query.new('', '')
    ].each do |query|
      assert_equal [], query.locations
    end
  end

  def test_locations
    query = OSRM::Query.new('21,78',
                            '-3.076,37.353',
                            '72,-40',
                            '-13.163,-72.546')

    assert_equal 4, query.locations.size
    assert_equal '-13.163,-72.546', query.locations.last
  end
end
