# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION
ENV['LOAD_ADAPTER_EXTENSIONS'] = 'mysql'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'fastercsv'
  config.gem 'mperham-memcache-client', :lib => 'memcache', :source => 'http://gems.github.com' # bugfix tweak of standard memcache client
  config.gem 'dancroak-webster', :lib => 'webster', :source => 'http://gems.github.com'
  config.gem 'color-tools', :lib => 'color', :source => 'http://gems.github.com'
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  config.middleware.use Rack::Deflater
  
  config.cache_store = :mem_cache_store
end

class ::Array; def mean; sum / size; end; end # monkeypatch for convenience

WEBSTER = Webster.new # Random word generator
Workling::Return::Store.instance = Workling::Return::Store::StarlingReturnStore.new

THREADS = 4 # client scraping threads to run

METHODS = %w(jquery jquery_noinsert reuse_noinsert reuse_insert reuse_reinsert full_reinsert).sort
USER_AGENTS = %w( Explorer OmniWeb Opera Safari iCab Konqueror Firefox Camino Netscape Mozilla Chrome Unknown ).sort
i = 0
HUES = METHODS.inject({}){|m, method| m[method] = (0 + (i * 1.0 / METHODS.count)) % 1.0; i += 1; m } # 0 = base hue
i = 0
LUMINOSITIES = USER_AGENTS.inject({}){|m, method| m[method] = (i * 0.5 / (USER_AGENTS.count - 1)) + 0.25; i += 1; m }
