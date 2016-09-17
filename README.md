## OSRM Gem

OSRM Gem is a Ruby API that allows you to request [Open Source Routing Machine](http://project-osrm.org/) servers.
You can [run your own server](https://github.com/Project-OSRM/osrm-backend/wiki) or use the [demo server](https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy).

## Usage

1. Install OSRM Gem

        gem install osrm

2. Configure

        require 'osrm'
        OSRM.configure(

          # Connection
          server:     'example.com',      # Must be specified
          port:       8080,               # Default: 80 or 443 if SSL
          use_ssl:    true,               # Default: false

          # Connection (advanced)
          timeout:        10,                               # Default: 3
          user_agent:     'MyScript/1.1',                   # Default: 'OSRMRubyGem/{version}'
          before_request: -> { sleep 1 },                   # Default: nil
          after_request:  -> { puts 'Request performed!' }, # Default: nil

          # Caching
          # The cache can be any object providing [] and []= methods.
          # The cache key must contain the {url} pattern.
          cache:      {},                 # Default: nil (no cache)
          cache_key:  'my-script:{url}',  # Default: 'osrm:{url}'

          # Requests
          # Specify the precision of the overview geometries returned
          overview: :full                 # Possible values: false, :simplified (default), :full

        )

3. Request

        OSRM.routes('50.202712,8.582738', '50.20232,8.574447')
        OSRM.route('50.202712,8.582738', '50.20232,8.574447')

## License

OSRM Gem is released under [MIT License](http://opensource.org/licenses/MIT).
