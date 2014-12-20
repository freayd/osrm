## OSRM Gem

OSRM Gem is a Ruby API that allows you to request [Open Source Routing Machine](http://project-osrm.org/) servers.
You can [run your own server](https://github.com/Project-OSRM/osrm-backend/wiki) or use the [demo server](https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy).

## Usage

1. Install OSRM Gem

        gem install osrm

2. Configure

        require 'osrm'
        OSRM.configure(
          server:     'example.com',
          port:       8080,          # Default: 80 or 443 if SSL
          use_ssl:    true,          # Default: false
          timeout:    10,            # Default: 3
          user_agent: 'MyScript/1.1' # Default: OSRMRubyGem/{version}
        )

3. Request

        OSRM.routes('50.202712,8.582738', '50.20232,8.574447')
        OSRM.route('50.202712,8.582738', '50.20232,8.574447')

## License

OSRM Gem is released under [MIT License](http://opensource.org/licenses/MIT).
