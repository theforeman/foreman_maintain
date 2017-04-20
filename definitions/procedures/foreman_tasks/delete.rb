module Procedures::ForemanTasks
  class Delete < ForemanMaintain::Procedure
    def initialize(options = {})
      @state = options[:state]

      self.class.instance_exec(@state) do |state|
        metadata do
          description "Delete #{state} tasks"
        end
      end
    end

    def run
      with_spinner("Deleting #{@state} task") do |spinner|
        count_tasks_before = feature(:foreman_tasks).count(@state)

        if count_tasks_before > 0
          spinner.update "Backup #{@state} tasks"

          feature(:foreman_tasks).backup_tasks(@state) do |backup_progress|
            spinner.update backup_progress
          end

          spinner.update "Deleting #{@state} tasks [running]"
          count_tasks_later = feature(:foreman_tasks).delete(@state)
          spinner.update "Deleting #{@state} tasks [DONE]"
        end

        spinner.update(
          "Deleted #{@state} stopped and paused tasks: #{count_tasks_before - count_tasks_later}"
        )
      end
    end
  end
end
