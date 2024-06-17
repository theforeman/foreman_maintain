require 'foreman_maintain/utils/service/systemd'

class Features::Pulpcore < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::PulpCommon

  TIMEOUT_FOR_TASKS_STATUS = 300
  RETRY_INTERVAL_FOR_TASKS_STATE = 10

  metadata do
    label :pulpcore
  end

  def cli(args)
    parse_json(execute("pulp --format json #{args}"))
  end

  def running_tasks
    cli('task list --state-in running --state-in canceling')
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
      '/etc/pulp/settings.py',
      '/etc/pulp/certs/database_fields.symmetric.key',
    ]
  end

  def self.pulpcore_common_services
    [
      ForemanMaintain::Utils.system_service('pulpcore-api', 10, :socket => 'pulpcore-api'),
      ForemanMaintain::Utils.system_service('pulpcore-content', 10, :socket => 'pulpcore-content'),
    ]
  end
end
