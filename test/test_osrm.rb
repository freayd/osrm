require 'helper'

class TestOSRM < Minitest::Test
  def test_configure
    OSRM.configure(server: 'example.com', port: 123)
    assert_equal 'example.com', OSRM.configuration.server
    assert_equal 123, OSRM.configuration.port
  end

  def test_configuration_singleton
    assert_same OSRM::Configuration.instance, OSRM.configuration
  end
end
