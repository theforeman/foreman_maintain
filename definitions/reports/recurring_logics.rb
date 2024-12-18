# frozen_string_literal: true

module Checks
  module Report
    class RecurringLogics < ForemanMaintain::Report
      metadata do
        description 'Check if recurring logics are used'
      end

      REX_TASK_GROUP_CTE = <<~SQL
        WITH recurring_remote_execution_task_group_ids AS (
          SELECT task_group_id
          FROM foreman_tasks_task_groups as fttg
          INNER JOIN foreman_tasks_task_group_members AS fttgm
            ON fttgm.task_group_id = fttg.id
          INNER JOIN foreman_tasks_tasks AS ftt
            ON fttgm.task_id = ftt.id
          WHERE
            fttg.type = 'ForemanTasks::TaskGroups::RecurringLogicTaskGroup'
            AND ftt.label = 'Actions::RemoteExecution::RunHostsJob'
        ), indefinite_rex_recurring_logics AS (
          SELECT * FROM foreman_tasks_recurring_logics AS ftrl
          WHERE ftrl.task_group_id IN (SELECT task_group_id FROM recurring_remote_execution_task_group_ids)
            AND (ftrl.end_time IS NULL OR ftrl.max_iteration IS NULL)
        )
      SQL

      def run
        self.data = {}
        data['recurring_logics_indefinite_rex_count'] = sql_count('indefinite_rex_recurring_logics')
        data['recurring_logics_indefinite_rex_ansible_count'] =
          sql_count("indefinite_rex_recurring_logics WHERE purpose LIKE 'ansible-%'")
      end

      private

      def sql_count(query)
        super(query, cte: REX_TASK_GROUP_CTE)
      end
    end
  end
end
