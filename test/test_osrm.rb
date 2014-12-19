require 'helper'

class TestOSRM < Minitest::Test
  def test_configure
    OSRM.configure(
      server:     'example.com',
      port:       123,
      use_ssl:    true,
      timeout:    10,
      user_agent: 'Agent/2.0',
      invalid:    'invalid option!'
    )
    assert_equal 'example.com', OSRM.configuration.server
    assert_equal 123, OSRM.configuration.port
    assert OSRM.configuration.use_ssl?
    assert_equal 10, OSRM.configuration.timeout
    assert_equal 'Agent/2.0', OSRM.configuration.user_agent
    refute_respond_to OSRM.configuration, :invalid
  end

  def test_configuration_singleton
    assert_same OSRM::Configuration.instance, OSRM.configuration
  end
end
