module Checks::Pulpcore
  class NoRunningTasks < ForemanMaintain::Check
    metadata do
      for_feature :pulpcore
      description 'Check for running pulpcore tasks'
      tags :pre_upgrade
      param :wait_for_tasks,
        'Wait for tasks to finish or fail directly',
        :required => false
    end

    def run
      tasks = feature(:pulpcore).running_tasks
      assert(
        tasks.empty?,
        failure_message(tasks.length),
        :next_steps => calculate_next_steps
      )
    end

    private

    def failure_message(task_count)
      <<~MSG
        There are #{task_count} active task(s) in the system.
        Please wait for these to complete.
      MSG
    end

    def calculate_next_steps
      @wait_for_tasks ? [Procedures::Pulpcore::WaitForTasks.new] : []
    end
  end
end
