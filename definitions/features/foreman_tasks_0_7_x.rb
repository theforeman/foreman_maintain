require 'features/foreman_tasks_0_6_x'

class Features::ForemanTasks_0_7_x < Features::ForemanTasks_0_6_x
  detect do
    self.new if check_min_version('tfm-rubygem-foreman-tasks', '0.7')
  end

  def running_tasks_count
    feature(:foreman_database).query(<<-SQL).first['count'].to_i
      SELECT count(*) AS count FROM foreman_tasks_tasks WHERE state in ('running', 'paused')
    SQL
  end
end
