class Features::PulpcoreDatabase < ForemanMaintain::Feature
  PULPCORE_DB_CONFIG = '/etc/pulp/settings.py'.freeze

  include ForemanMaintain::Concerns::BaseDatabase
  include ForemanMaintain::Concerns::DirectoryMarker
  include ForemanMaintain::Concerns::PulpCommon

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
        :db_feature => feature(:pulpcore_database)),
    ]
  end

  private

  def load_configuration
    python_command = <<~PYTHON.strip
      from django.conf import settings; import json; print(json.dumps(settings.DATABASES["default"]))
    PYTHON
    manager_command = pulpcore_manager("shell --command '#{python_command}'")
    manager_result = execute!(manager_command, merge_stderr: false)
    db_config = JSON.parse(manager_result)

    @configuration = {}
    @configuration['adapter'] = 'postgresql'
    @configuration['host'] = db_config['HOST']
    @configuration['port'] = db_config['PORT']
    @configuration['database'] = db_config['NAME']
    @configuration['username'] = db_config['USER']
    @configuration['password'] = db_config['PASSWORD']
    @configuration
  end
end
