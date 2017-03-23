class Features::ForemanTasks < ForemanMaintain::Feature
  metadata do
    label :foreman_tasks

    confine do
      check_min_version('ruby193-rubygem-foreman-tasks', '0.6') ||
        check_min_version('tfm-rubygem-foreman-tasks', '0.7')
    end
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
      sql << "AND label NOT IN (#{ignored_tasks.map { |task| "'#{task}'" }.join(',')})"
    end
    feature(:foreman_database).query(sql).first['count'].to_i
  end
end
