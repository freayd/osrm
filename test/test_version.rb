require 'helper'

class TestVersion < Minitest::Test
  def test_version
    assert_match /\A\d+\.\d+\.\d+\z/, OSRM::VERSION
  end
end
