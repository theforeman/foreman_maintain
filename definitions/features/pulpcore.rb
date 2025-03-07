require 'foreman_maintain/utils/service/systemd'

class Features::Pulpcore < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::PulpCommon

  TIMEOUT_FOR_TASKS_STATUS = 300
  RETRY_INTERVAL_FOR_TASKS_STATE = 10
  PULP_SETTINGS = '/etc/pulp/settings.py'.freeze
  PULP_CLI_SETTINGS = '/etc/pulp/cli.toml'.freeze

  metadata do
    label :pulpcore

    confine do
      File.exist?(PULP_SETTINGS)
    end
  end

  def cli_available?
    File.exist?(PULP_CLI_SETTINGS)
  end

  def cli(args)
    parse_json(execute!("pulp --format json #{args}", merge_stderr: false))
  end

  def running_tasks
    tasks = cli('task list --state-in running --state-in canceling')
    # cli() uses parse_json() which swallows JSON::ParserError and returns nil
    # but running_tasks should return an Array
    if tasks.nil?
      []
    else
      tasks
    end
  rescue ForemanMaintain::Error::ExecutionError
    []
  end

  def wait_for_tasks(spinner, timeout_for_tasks_status = TIMEOUT_FOR_TASKS_STATUS)
    Timeout.timeout(timeout_for_tasks_status) do
      while (task_count = running_tasks.length) != 0
        puts "\nThere are #{task_count} tasks."
        spinner.update "Waiting #{RETRY_INTERVAL_FOR_TASKS_STATE} seconds before retry."
        sleep RETRY_INTERVAL_FOR_TASKS_STATE
      end
    end
  rescue Timeout::Error => e
    logger.error(e.message)
    puts "\nTimeout: #{e.message}. Try again."
  end

  def services
    redis_services = feature(:redis) ? feature(:redis).services : []

    self.class.pulpcore_common_services + configured_workers +
      redis_services
  end

  def configured_workers
    names = Dir['/etc/systemd/system/multi-user.target.wants/pulpcore-worker@*.service']
    names = names.map { |f| File.basename(f) }
    names.map do |name|
      system_service(name, 20, :skip_enablement => true,
        :instance_parent_unit => 'pulpcore-worker@')
    end
  end

  def config_files
    [
      PULP_SETTINGS,
      '/etc/pulp/certs/database_fields.symmetric.key',
    ]
  end

  def self.pulpcore_common_services
    [
      ForemanMaintain::Utils.system_service('pulpcore-api', 20, :socket => 'pulpcore-api'),
      ForemanMaintain::Utils.system_service('pulpcore-content', 20, :socket => 'pulpcore-content'),
    ]
  end
end
