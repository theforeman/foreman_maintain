class Features::ForemanTasks < ForemanMaintain::Feature
  feature_name :foreman_tasks

  detect do
    new if check_min_version('ruby193-rubygem-foreman-tasks', '0.6') ||
      check_min_version('tfm-rubygem-foreman-tasks', '0.7')
  end

  def running_tasks_count
    #feature(:foreman_database).query(<<-SQL).first['count'].to_i
    #  SELECT count(*) AS count FROM foreman_tasks_tasks WHERE state in ('running', 'paused')
    #SQL
    0
  end

  def paused_tasks_count
    #feature(:foreman_database).query(<<-SQL).first['count'].to_i
    #  SELECT count(*) AS count FROM foreman_tasks_tasks WHERE state in ('running', 'paused')
    #SQL
    sleep 3
    4
  end
end
