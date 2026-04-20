require 'uri'
require 'cgi'

class Features::CandlepinDatabase < ForemanMaintain::Feature
  CANDLEPIN_DB_CONFIG = '/etc/candlepin/candlepin.conf'.freeze

  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :candlepin_database

    confine do
      file_nonzero?(CANDLEPIN_DB_CONFIG)
    end
  end

  def services
    [
      system_service('postgresql', 10, :component => 'candlepin',
        :db_feature => feature(:candlepin_database)),
    ]
  end

  def configuration
    @configuration ||= load_configuration
  end

  def check_option_using_cpdb_help(option_name, parent_cmd = '')
    parent_cmd = '/usr/share/candlepin/cpdb' if parent_cmd.empty?
    help_cmd = "#{parent_cmd} --help |  grep -c '\\-\\-#{option_name}'"
    execute?(help_cmd)
  end

  private

  def raw_config
    File.read(CANDLEPIN_DB_CONFIG)
  end

  def load_configuration
    full_config = Hash[raw_config.scan(/(^[^#\n][^=]*)=(.*)/)]
    url = full_config['jpa.config.hibernate.connection.url']
    uri = URI.parse(url.delete_prefix('jdbc:'))
    query = uri.query ? CGI.parse(uri.query) : {}
    {
      'username' => full_config['jpa.config.hibernate.connection.username'],
      'password' => full_config['jpa.config.hibernate.connection.password'],
      'database' => uri.path,
      'host' => uri.host,
      'port' => uri.port || '5432',
      'ssl' => query['ssl']&.first == 'true',
      'sslfactory' => query['sslfactory']&.first,
      'driver_class' => full_config['jpa.config.hibernate.connection.driver_class'],
      'url' => url,
    }
  end

  def extend_with_db_options
    db_options = { '-d' => configuration['database'] }
    if check_option_using_cpdb_help('dbhost')
      db_options['--dbhost'] = configuration['host']
      db_options['--dbport'] = configuration['port']
    end
    db_options
  end
end
