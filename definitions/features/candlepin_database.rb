class Features::CandlepinDatabase < ForemanMaintain::Feature
  CANDLEPIN_DB_CONFIG = '/etc/candlepin/candlepin.conf'.freeze

  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :candlepin_database

    confine do
      file_exists?(CANDLEPIN_DB_CONFIG)
    end
  end

  def configuration
    @configuration || load_configuration
  end

  private

  def load_configuration
    raw_config = File.read(CANDLEPIN_DB_CONFIG)
    full_config = Hash[raw_config.scan(/(^[^#\n][^=]*)=(.*)/)]
    uri = %r{://(([^/:]*):?([^/]*))/(.*)}.match(full_config['org.quartz.dataSource.myDS.URL'])
    @configuration = {
      'username' => full_config['org.quartz.dataSource.myDS.user'],
      'password' => full_config['org.quartz.dataSource.myDS.password'],
      'database' => uri[4],
      'host' => uri[2],
      'port' => uri[3] || '5432'
    }
  end
end
