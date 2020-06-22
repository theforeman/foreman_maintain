require 'foreman_maintain/utils/backup'

module ForemanMaintain::Scenarios
  class Restore < ForemanMaintain::Scenario
    metadata do
      description 'Restore backup'
      param :backup_dir, 'Path to backup directory'
      param :incremental_backup, 'Is the backup incremental?'
      manual_detection
    end

    # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    def compose
      backup = ForemanMaintain::Utils::Backup.new(context.get(:backup_dir))

      add_steps(find_checks(:root_user))
      supported_version_check
      add_steps_with_context(Checks::Restore::ValidateBackup,
                             Procedures::Restore::Confirmation,
                             Checks::Restore::ValidateHostname,
                             Procedures::Selinux::SetFileSecurity,
                             Procedures::Restore::Configs)
      add_step_with_context(Procedures::Crond::Stop) if feature(:cron)
      unless backup.incremental?
        add_steps_with_context(Procedures::Restore::EnsureMongoEngineMatches,
                               Procedures::Restore::InstallerReset)
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
      restore_mongo_dump(backup)
      add_steps_with_context(Procedures::Pulp::Migrate,
                             Procedures::Pulpcore::Migrate)

      add_steps_with_context(Procedures::Restore::RegenerateQueues) if backup.online_backup?
      add_steps_with_context(Procedures::Service::Start,
                             Procedures::Service::DaemonReload)
      add_step_with_context(Procedures::Crond::Start) if feature(:cron)
    end
    # rubocop:enable Metrics/MethodLength,Metrics/AbcSize

    def drop_dbs(backup)
      if backup.file_map[:candlepin_dump][:present] ||
         backup.file_map[:foreman_dump][:present] ||
         (feature(:pulpcore) && backup.file_map[:pulpcore_dump][:present])
        add_steps_with_context(Procedures::Restore::DropDatabases)
      end
    end

    def restore_sql_dumps(backup)
      if backup.file_map[:pg_globals][:present]
        add_steps_with_context(Procedures::Restore::PgGlobalObjects)
      end
      if backup.file_map[:candlepin_dump][:present]
        add_steps_with_context(Procedures::Restore::CandlepinDump)
      end
      if backup.file_map[:foreman_dump][:present]
        add_steps_with_context(Procedures::Restore::ForemanDump)
      end
      if feature(:pulpcore) && backup.file_map[:pulpcore_dump][:present]
        add_steps_with_context(Procedures::Restore::PulpcoreDump)
      end
    end

    def restore_mongo_dump(backup)
      if backup.file_map[:mongo_dump][:present]
        add_steps_with_context(Procedures::Restore::MongoDump)
      end
    end

    def supported_version_check
      if feature(:instance).downstream && feature(:instance).downstream.less_than_version?('6.3')
        msg = 'ERROR: Restore subcommand is supported by Satellite 6.3+. ' \
              'Please use katello-restore instead.'
        abort(msg)
      end
    end

    def set_context_mapping
      context.map(:backup_dir,
                  Checks::Restore::ValidateBackup => :backup_dir,
                  Checks::Restore::ValidateHostname => :backup_dir,
                  Procedures::Restore::Configs => :backup_dir,
                  Procedures::Restore::DropDatabases => :backup_dir,
                  Procedures::Restore::PgGlobalObjects => :backup_dir,
                  Procedures::Restore::CandlepinDump => :backup_dir,
                  Procedures::Restore::ForemanDump => :backup_dir,
                  Procedures::Restore::PulpcoreDump => :backup_dir,
                  Procedures::Restore::ExtractFiles => :backup_dir,
                  Procedures::Restore::MongoDump => :backup_dir)

      context.map(:incremental_backup,
                  Procedures::Selinux::SetFileSecurity => :incremental_backup)
    end
  end

  class RestoreRescue < ForemanMaintain::Scenario
    metadata do
      description 'Resuce Restore backup'
      manual_detection
    end

    def compose
      add_step_with_context(Procedures::Crond::Stop) if feature(:cron)
    end
  end
end
