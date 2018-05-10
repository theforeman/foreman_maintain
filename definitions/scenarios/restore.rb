require 'foreman_maintain/utils/backup'

module ForemanMaintain::Scenarios
  class Restore < ForemanMaintain::Scenario
    metadata do
      description 'Restore backup'
      param :backup_dir, 'Path to backup directory'
      param :incremental_backup, 'Is the backup incremental?'
      manual_detection
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def compose
      backup = ForemanMaintain::Utils::Backup.new(context.get(:backup_dir))

      add_steps(find_checks(:root_user))
      supported_version_check
      add_steps_with_context(Checks::Restore::ValidateBackup,
                             Procedures::Restore::Confirmation,
                             Checks::Restore::ValidateHostname,
                             Procedures::Selinux::SetFileSecurity,
                             Procedures::Restore::Configs,
                             Procedures::Restore::InstallerReset,
                             Procedures::Service::Stop)
      add_steps_with_context(Procedures::Restore::ExtractFiles) if backup.tar_backups_exist?
      add_steps_with_context(Procedures::Restore::DropDatabases)
      if backup.file_map[:pg_globals][:present]
        add_steps_with_context(Procedures::Restore::PgGlobalObjects)
      end
      if backup.sql_dump_files_exist? && feature(:instance).postgresql_local?
        feature(:service).handle_services(spinner, 'start', :only => ['postgresql'])
      end
      if backup.file_map[:candlepin_dump][:present]
        add_steps_with_context(Procedures::Restore::CandlepinDump)
      end
      if backup.file_map[:foreman_dump][:present]
        add_steps_with_context(Procedures::Restore::ForemanDump)
      end
      if backup.sql_dump_files_exist? && feature(:instance).postgresql_local?
        feature(:service).handle_services(spinner, 'stop', :only => ['postgresql'])
      end
      if backup.file_map[:mongo_dump][:present]
        add_steps_with_context(Procedures::Restore::MongoDump)
      end
      add_steps_with_context(Procedures::Pulp::Migrate,
                             Procedures::Service::Start,
                             Procedures::Service::DaemonReload)
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def supported_version_check
      if feature(:downstream) && feature(:downstream).less_than_version?('6.3')
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
                  Procedures::Restore::ExtractFiles => :backup_dir,
                  Procedures::Restore::MongoDump => :backup_dir)

      context.map(:incremental_backup,
                  Procedures::Selinux::SetFileSecurity => :incremental_backup,
                  Procedures::Restore::InstallerReset => :incremental_backup)
    end
  end
end
