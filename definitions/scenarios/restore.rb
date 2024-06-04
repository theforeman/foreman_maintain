require 'foreman_maintain/utils/backup'

module ForemanMaintain::Scenarios
  class Restore < ForemanMaintain::Scenario
    metadata do
      description 'Restore backup'
      param :backup_dir, 'Path to backup directory'
      param :incremental_backup, 'Is the backup incremental?'
      param :dry_run, 'Check if backup could be restored, without performing the restore'
      manual_detection
    end

    # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def compose
      backup = ForemanMaintain::Utils::Backup.new(context.get(:backup_dir))

      add_steps(find_checks(:root_user))
      add_steps_with_context(Checks::Restore::ValidateBackup,
        Checks::Restore::ValidateHostname,
        Checks::Restore::ValidateInterfaces,
        Checks::Restore::ValidatePostgresqlDumpPermissions)

      if context.get(:dry_run)
        self.class.metadata[:run_strategy] = :fail_slow
        return
      end

      add_steps_with_context(Procedures::Restore::Confirmation,
        Procedures::Selinux::SetFileSecurity,
        Procedures::Restore::RequiredPackages,
        Procedures::Restore::Configs)
      add_step_with_context(Procedures::Crond::Stop) if feature(:cron)
      unless backup.incremental?
        add_steps_with_context(Procedures::Restore::InstallerReset)
      end
      add_step_with_context(Procedures::Service::Stop)
      add_steps_with_context(Procedures::Restore::ExtractFiles) if backup.tar_backups_exist?
      drop_dbs(backup)
      if backup.sql_dump_files_exist? && feature(:instance).postgresql_local?
        add_step(Procedures::Service::Start.new(:only => ['postgresql']))
      end
      restore_sql_dumps(backup)
      if backup.sql_dump_files_exist? && feature(:instance).postgresql_local?
        add_step(Procedures::Service::Stop.new(:only => ['postgresql']))
      end

      if feature(:instance).postgresql_local? &&
         !backup.online_backup? &&
         backup.different_source_os?
        add_step_with_context(Procedures::Restore::ReindexDatabases)
      end

      add_step(Procedures::Installer::Run.new(:assumeyes => true))
      add_step_with_context(Procedures::Installer::UpgradeRakeTask)
      add_step_with_context(Procedures::Crond::Start) if feature(:cron)
    end
    # rubocop:enable Metrics/MethodLength,Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    def drop_dbs(backup)
      if backup.file_map[:candlepin_dump][:present] ||
         backup.file_map[:foreman_dump][:present] ||
         backup.file_map[:pulpcore_dump][:present]
        add_steps_with_context(Procedures::Restore::DropDatabases)
      end
    end

    def restore_sql_dumps(backup)
      if backup.file_map[:candlepin_dump][:present]
        add_steps_with_context(Procedures::Restore::CandlepinDump)
      end
      if backup.file_map[:foreman_dump][:present]
        add_steps_with_context(Procedures::Restore::ForemanDump)
      end
      if backup.file_map[:pulpcore_dump][:present]
        add_steps_with_context(Procedures::Restore::PulpcoreDump)
      end
    end

    def set_context_mapping
      context.map(:backup_dir,
        Checks::Restore::ValidateBackup => :backup_dir,
        Checks::Restore::ValidateHostname => :backup_dir,
        Checks::Restore::ValidateInterfaces => :backup_dir,
        Checks::Restore::ValidatePostgresqlDumpPermissions => :backup_dir,
        Procedures::Restore::RequiredPackages => :backup_dir,
        Procedures::Restore::Configs => :backup_dir,
        Procedures::Restore::DropDatabases => :backup_dir,
        Procedures::Restore::CandlepinDump => :backup_dir,
        Procedures::Restore::ForemanDump => :backup_dir,
        Procedures::Restore::PulpcoreDump => :backup_dir,
        Procedures::Restore::ExtractFiles => :backup_dir)

      context.map(:incremental_backup,
        Procedures::Selinux::SetFileSecurity => :incremental_backup)
    end
  end

  class RestoreRescue < ForemanMaintain::Scenario
    metadata do
      description 'Rescue Restore backup'
      manual_detection
    end

    def compose
      add_step_with_context(Procedures::Crond::Stop) if feature(:cron)
    end
  end
end
