require 'helper'

class TestConfiguration < Minitest::Test
  def setup
    @configuration = OSRM::Configuration.send(:new)
  end

  def test_defaults
    assert_nil @configuration.server
    assert_nil @configuration.port
    refute @configuration.use_ssl?
    assert_nil @configuration.api_key
    assert_empty @configuration.path_prefix

    assert_equal 3, @configuration.timeout
    assert_match(/\AOSRMRubyGem\/\d+\.\d+\.\d+\z/, @configuration.user_agent)
    assert_nil @configuration.before_request
    assert_nil @configuration.after_request

    assert_nil @configuration.cache
    assert_match(/\A.{2,10}\{url\}\z/, @configuration.cache_key)

    assert_equal :simplified, @configuration.overview

    refute @configuration.use_demo_server?
    refute @configuration.use_mapbox_server?
  end

  def test_merge
    @configuration.server  = 'server.com'
    @configuration.port    = 51
    @configuration.use_ssl = true
    @configuration.path_prefix = '/path/example'
    @configuration.before_request = -> {}
    @configuration.after_request  = -> {}
    @configuration.cache   = nil
    @configuration.merge!(
      port:    123,
      use_ssl: false,
      api_key: '0123456789',
      invalid: 'invalid option!',

      timeout:       42,
      user_agent:    'OneAgent/6.0',
      after_request: nil,

      cache:      {},
      cache_key:  'one-agent-{url}',

      overview: false
    )
    assert_equal 'server.com', @configuration.server
    assert_equal 123, @configuration.port
    refute @configuration.use_ssl?
    assert_equal '0123456789', @configuration.api_key
    assert_equal '/path/example', @configuration.path_prefix

    assert_equal 42, @configuration.timeout
    assert_equal 'OneAgent/6.0', @configuration.user_agent
    assert_kind_of Proc, @configuration.before_request
    assert_nil @configuration.after_request

    assert_kind_of Hash, @configuration.cache
    assert_empty @configuration.cache
    assert_equal 'one-agent-{url}', @configuration.cache_key
    assert_equal 'one-agent-example.com', @configuration.cache_key('example.com')
    refute_respond_to @configuration, :invalid

    assert_equal false, @configuration.overview

    assert_same @configuration, @configuration.merge!(key: 'value')
  end

  def test_server
    @configuration.server = 'example.com'
    assert_equal 'example.com', @configuration.server
    refute @configuration.use_demo_server?
    refute @configuration.use_mapbox_server?
  end

  def test_demo_server
    @configuration.server = :demo
    assert_equal OSRM::Configuration::DEMO_SERVER, @configuration.server
    assert @configuration.use_demo_server?
  end

   def test_mapbox_server
     @configuration.use_ssl = false
     @configuration.server = :mapbox
     assert_equal OSRM::Configuration::MAPBOX_SERVER, @configuration.server
     assert @configuration.use_mapbox_server?
     assert @configuration.use_ssl?
   end

  def test_port
    @configuration.port = '123'
    assert_equal 123, @configuration.port
    assert_instance_of Integer, @configuration.port
  end

  def test_ssl_true
    @configuration.use_ssl = true
    assert @configuration.use_ssl?
  end

  def test_ssl_false
    @configuration.use_ssl = false
    refute @configuration.use_ssl?
  end

  def test_api_key
    @configuration.api_key = '6uKfQuAe2Y'
    assert_equal '6uKfQuAe2Y', @configuration.api_key
  end

  def test_path_prefix
    @configuration.path_prefix = '/dir/subdir'
    assert_equal '/dir/subdir', @configuration.path_prefix
  end

  def test_invalid_path_prefix_1
    assert_raises(RuntimeError) { @configuration.path_prefix = 'dir/subdir' }
  end

  def test_invalid_path_prefix_2
    assert_raises(RuntimeError) { @configuration.path_prefix = '/dir/subdir/' }
  end

  def test_timeout
    @configuration.timeout = 5.0
    assert_equal 5, @configuration.timeout
    assert_instance_of Integer, @configuration.timeout
  end

  def test_user_agent
    @configuration.user_agent = 'Bot/0.1'
    assert_equal 'Bot/0.1', @configuration.user_agent
  end

  def test_before_after_request
    @configuration.before_request = proc {}
    @configuration.after_request  = -> {}
    assert_kind_of Proc, @configuration.before_request
    assert_kind_of Proc, @configuration.after_request
    refute @configuration.before_request.lambda?
    assert @configuration.after_request.lambda?
  end

  def test_invalid_before_after_request
    assert_raises(RuntimeError) { @configuration.before_request = 'not a Proc' }
    assert_raises(RuntimeError) { @configuration.after_request = ['not a Proc'] }
  end

  def test_nil_cache
    @configuration.cache = nil
    assert_nil @configuration.cache
  end

  def test_cache
    @configuration.cache = { 'a' => '1', 'b' => '2' }
    refute_empty @configuration.cache
    assert_equal '1', @configuration.cache['a']
    assert_equal '2', @configuration.cache['b']
  end

  def test_valid_cache_version_1
    @configuration.cache = { 'test#version' => '9.9.9' }
    @configuration.cache_key = 'test#{url}'
  end

  def test_valid_cache_version_2
    @configuration.cache_key = 'test|{url}'
    @configuration.cache = { 'test|version' => '0.4.0' }
  end

  def test_invalid_cache_version_1
    @configuration.cache_key = 'test/{url}'
    assert_raises(RuntimeError) { @configuration.cache = { 'test/version' => '0.3.9' } }
  end

  def test_invalid_cache_version_2
    @configuration.cache = { 'test!version' => '0.3.9' }
    assert_raises(RuntimeError) { @configuration.cache_key = 'test!{url}' }
  end

  def test_relative_cache_version
    @configuration.cache = { 'test,version' => OSRM::VERSION }
    @configuration.cache_key = 'test,{url}'

    v = Gem::Version.new(OSRM::VERSION).release.to_s.split('.').map(&:to_i)
    prev_minor = v.each_with_index.map { |x,i| i == 1 ? x - 1 : (i == 2 ?  0 : x) }.join('.')
    patch_zero = v.each_with_index.map { |x,i| i == 2 ?     0 : x }.join('.')
    next_patch = v.each_with_index.map { |x,i| i == 2 ? x + 1 : x }.join('.')
    next_minor = v.each_with_index.map { |x,i| i == 1 ? x + 1 : (i == 2 ?  0 : x) }.join('.')
    next_major = v.each_with_index.map { |x,i| i == 0 ? x + 1 : 0 }.join('.')

    assert_raises(RuntimeError) { @configuration.cache = { 'test,version' => prev_minor } }
                                  @configuration.cache = { 'test,version' => patch_zero }
                                  @configuration.cache = { 'test,version' => next_patch }
                                  @configuration.cache = { 'test,version' => next_minor }
                                  @configuration.cache = { 'test,version' => next_major }
  end

  def test_cache_key
    @configuration.cache_key = 'test $ {url}'
    assert_equal 'test $ {url}', @configuration.cache_key
    assert_equal 'test $ http://hello', @configuration.cache_key('http://hello')
  end

  def test_invalid_cache_key
    assert_raises(RuntimeError) { @configuration.cache_key = 'invalid key' }
  end

  def test_overview
    [false, :simplified, :full].each do |overview|
      @configuration.overview = overview
      assert_equal overview, @configuration.overview
    end

    assert_raises(RuntimeError) { @configuration.overview = nil    }
    assert_raises(RuntimeError) { @configuration.overview = :foo   }
    assert_raises(RuntimeError) { @configuration.overview = :fulll }
  end
end
