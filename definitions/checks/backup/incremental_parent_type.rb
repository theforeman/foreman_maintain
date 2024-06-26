module Checks::Backup
  class IncrementalParentType < ForemanMaintain::Check
    metadata do
      description 'Check if the incremental backup has the right type'
      tags :backup
      param :incremental_dir, 'Path to existing backup directory'
      param :online_backup, 'Select for online backup', :flag => true, :default => false
      param :sql_tar, 'Will backup include PostgreSQL tarball', :flag => true, :default => false
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
        existing_sql = backup.sql_tar_files_exist? ? 'tarball' : 'dump'
        new_sql = @sql_tar ? 'tarball' : 'dump'
        msg = "The existing backup has PostgreSQL as a #{existing_sql}, "\
          "but the new one will have a #{new_sql}."
        assert(existing_sql == new_sql, msg)
      end
    end
  end
end
