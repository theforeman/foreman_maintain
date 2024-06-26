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

      existing_type = backup.online_backup? ? 'online' : 'offline'
      new_type = @online_backup ? 'online' : 'offline'
      msg = "The existing backup is an #{existing_type} one, but an #{new_type} one was requested."
      assert(existing_type == new_type, msg)

      unless @online_backup
        msg = "The existing backup has PostgreSQL as a tarball, "\
          "but the new one will have a dump."
        assert(!backup.sql_tar_files_exist?, msg)
      end
    end
  end
end
