module ForemanMaintain
  module Cli
    class RestoreCommand < Base
      interactive_option
      parameter 'BACKUP_DIR', 'Path to backup directory to restore',
                :attribute_name => :backup_dir, :completion => { :directory => {} }

      option ['-i', '--incremental'], :flag, 'Restore an incremental backup',
             :attribute_name => :incremental, :completion => { :directory => {} }

      def execute
        scenario = Scenarios::Restore.new(
          :backup_dir => @backup_dir,
          :incremental_backup => @incremental || incremental_backup?
        )
        run_scenario(scenario)
        exit runner.exit_code
      end

      def incremental_backup?
        backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
        backup.incremental?
      end
    end
  end
end
