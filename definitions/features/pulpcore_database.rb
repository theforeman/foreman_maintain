class Features::PulpcoreDatabase < ForemanMaintain::Feature
  PULPCORE_DB_CONFIG = '/etc/pulp/settings.py'.freeze

  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :pulpcore_database

    confine do
      file_nonzero?(PULPCORE_DB_CONFIG)
    end
  end

  def configuration
    @configuration || load_configuration
  end

  def services
    [
      system_service('postgresql', 10, :component => 'pulpcore',
                                       :db_feature => feature(:pulpcore_database))
    ]
  end

  private

  def load_configuration
    full_config = File.read(PULPCORE_DB_CONFIG).split(/[\s,'":]/).reject(&:empty?)

    @configuration = {}
    @configuration['adapter'] = 'postgresql'
    @configuration['host'] = full_config[full_config.index('HOST') + 1]
    @configuration['port'] = full_config[full_config.index('PORT') + 1]
    @configuration['database'] = full_config[full_config.index('NAME') + 1]
    @configuration['username'] = full_config[full_config.index('USER') + 1]
    @configuration['password'] = full_config[full_config.index('PASSWORD') + 1]
    @configuration
  end
end
