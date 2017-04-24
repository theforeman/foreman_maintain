class Features::ForemanTasks < ForemanMaintain::Feature
  MIN_AGE = 30

  SAFE_TO_DELETE = %w[
    Actions::Katello::Host::GenerateApplicability
    Actions::Katello::RepositorySet::ScanCdn
    Actions::Katello::Host::Hypervisors
    Actions::Katello::Host::HypervisorsUpdate
    Actions::Foreman::Host::ImportFacts
    Actions::Candlepin::ListenOnCandlepinEvents
    Actions::Katello::EventQueue::Monitor
  ].freeze

  metadata do
    label :foreman_tasks

    confine do
      check_min_version('ruby193-rubygem-foreman-tasks', '0.6') ||
        check_min_version('tfm-rubygem-foreman-tasks', '0.7')
    end
  end

  def backup_tasks(state)
    backup_table('dynflow_execution_plans', state, 'uuid') { |status| yield(status) }
    backup_table('dynflow_steps', state) { |status| yield(status) }
    backup_table('dynflow_actions', state) { |status| yield(status) }

    yield('Backup Tasks [running]')
    export_csv("SELECT * FROM foreman_tasks_tasks WHERE #{condition(state)}",
               'foreman_tasks_tasks.csv', state)
    yield('Backup Tasks [DONE]')
    @backup_dir = nil
  end

  def running_tasks_count
    # feature(:foreman_database).query(<<-SQL).first['count'].to_i
    #  SELECT count(*) AS count FROM foreman_tasks_tasks WHERE state in ('running', 'paused')
    # SQL
    0
  end

  def paused_tasks_count(ignored_tasks = [])
    sql = <<-SQL
      SELECT count(*) AS count
        FROM foreman_tasks_tasks
        WHERE state IN ('paused')
    SQL
    unless ignored_tasks.empty?
      sql << "AND label NOT IN (#{quotize(ignored_tasks)})"
    end
    feature(:foreman_database).query(sql).first['count'].to_i
  end

  def count(state)
    feature(:foreman_database).query(<<-SQL).first['count'].to_i
     SELECT count(*) AS count FROM foreman_tasks_tasks WHERE #{condition(state)}
    SQL
  end

  def delete(state)
    tasks_condition = condition(state)

    feature(:foreman_database).psql(<<-SQL)
     BEGIN;
       DELETE FROM dynflow_steps USING foreman_tasks_tasks WHERE (foreman_tasks_tasks.external_id = dynflow_steps.execution_plan_uuid) AND #{tasks_condition};
       DELETE FROM dynflow_actions USING foreman_tasks_tasks WHERE (foreman_tasks_tasks.external_id = dynflow_actions.execution_plan_uuid) AND #{tasks_condition};
       DELETE FROM dynflow_execution_plans USING foreman_tasks_tasks WHERE (foreman_tasks_tasks.external_id = dynflow_execution_plans.uuid) AND #{tasks_condition};
       DELETE FROM foreman_tasks_tasks WHERE #{tasks_condition};
     COMMIT;
    SQL

    count(state)
  end

  def condition(state)
    raise 'Invalid State' unless valid(state)

    if state == :old
      old_tasks_condition
    else
      tasks_condition(state)
    end
  end

  private

  def backup_dir(state)
    @backup_dir ||=
      "/var/lib/foreman/backup-tasks/#{state}/#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}"
  end

  def backup_table(table, state, fkey = 'execution_plan_uuid')
    yield("Backup #{table} [running]")
    sql = "SELECT #{table}.* FROM foreman_tasks_tasks JOIN #{table} ON\
       (foreman_tasks_tasks.external_id = #{table}.#{fkey})"
    export_csv(sql, "#{table}.csv", state)
    yield("Backup #{table} [DONE]")
  end

  def export_csv(sql, file_name, state)
    dir = prepare_for_backup(state)
    filepath = "#{dir}/#{file_name}"
    execute("echo \"COPY (#{sql}) TO STDOUT WITH CSV;\" \
      | su - postgres -c '/usr/bin/psql -d foreman' | bzip2 -9 > #{filepath}.bz2")
  end

  def old_tasks_condition(state = "'stopped', 'paused'")
    "foreman_tasks_tasks.state IN (#{state}) AND " \
       "foreman_tasks_tasks.started_at < CURRENT_DATE - INTERVAL '#{MIN_AGE} days'"
  end

  def prepare_for_backup(state)
    dir = backup_dir(state)
    execute("mkdir -p #{dir}")
    dir
  end

  def quotize(array)
    array.map { |el| "'#{el}'" }.join(',')
  end

  def tasks_condition(state)
    safe_to_delete_tasks = quotize(SAFE_TO_DELETE)
    "foreman_tasks_tasks.state = '#{state}' AND " \
    "foreman_tasks_tasks.label IN (#{safe_to_delete_tasks})"
  end

  def valid(state)
    [:old, :planning, :pending].include?(state)
  end
end
