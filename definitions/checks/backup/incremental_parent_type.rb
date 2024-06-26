module Checks::Backup
  class IncrementalParentType < ForemanMaintain::Check
    metadata do
      description 'Check if the incremental backup has the right type'
      tags :backup
      param :incremental_dir, 'Path to existing backup directory'
      param :online_backup, 'Select for online backup', :flag => true, :default => false
      manual_detection
    end

    def run
      return unless @incremental_dir

      backup = ForemanMaintain::Utils::Backup.new(@incremental_dir)

      existing_type = backup.backup_type
      new_type = if @online_backup
                   ForemanMaintain::Utils::Backup::ONLINE_BACKUP
                 else
                   ForemanMaintain::Utils::Backup::OFFLINE_BACKUP
                 end
      msg = "The existing backup is an #{existing_type} backup, "\
        "but an #{new_type} backup was requested."
      assert(existing_type == new_type, msg)

      unless @online_backup
        msg = "The existing backup has PostgreSQL as a tarball, "\
          "but the new one will have a dump."
        assert(!backup.sql_tar_files_exist?, msg)
      end
    end
  end
end
