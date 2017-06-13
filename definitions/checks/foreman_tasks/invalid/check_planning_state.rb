module Checks::ForemanTasks
  module Invalid
    class CheckPlanningState < ForemanMaintain::Check
      metadata do
        label :check_foreman_tasks_in_planning_state
        for_feature :foreman_tasks
        tags :pre_upgrade
        description 'Check for tasks in planning state'
        after :check_foreman_tasks_in_pending_state
      end

      def run
        # Check and delete 'all tasks in planning state'
        tasks_in_planning_count = feature(:foreman_tasks).count(:planning)
        assert(tasks_in_planning_count <= 0,
               "Found #{tasks_in_planning_count} task(s) in planning state",
               :next_steps => Procedures::ForemanTasks::Delete.new(:state => :planning))
      end
    end
  end
end
