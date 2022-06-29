class Features::ForemanDatabase < ForemanMaintain::Feature
  FOREMAN_DB_CONFIG = '/etc/foreman/database.yml'.freeze

  include ForemanMaintain::Concerns::BaseDatabase

  metadata do
    label :foreman_database

    confine do
      file_nonzero?(FOREMAN_DB_CONFIG)
    end
  end

  def configuration
    @configuration || load_configuration
  end

  def config_files
    [postgresql_conf] if el?

    []
  end

  def config_dirs
    # On Debian config files reside in /etc/postgresql/#{version}/main/
    # There could be more than on config dir because of multiple versions
    deb_psql_conf_dirs
  end

  def services
    [
      system_service('postgresql', 10, :component => 'foreman',
                                       :db_feature => feature(:foreman_database))
    ]
  end

  private

  def load_configuration
    config = YAML.load(File.read(FOREMAN_DB_CONFIG))
    @configuration = config['production']
    @configuration['host'] ||= 'localhost'
    @configuration
  end
end
