require 'foreman_maintain/utils/backup'

module ForemanMaintain::Scenarios
  class Restore < ForemanMaintain::Scenario
    metadata do
      description 'Restore backup'
      param :backup_dir, 'Path to backup directory'
      param :incremental_backup, 'Is the backup incremental?'
    end

    # rubocop:disable Metrics/MethodLength
    def compose
      add_steps(find_checks(:root_user))
      if feature(:downstream) && feature(:downstream).less_than_version?('6.3')
        msg = 'ERROR: Restore subcommand is supported by Satellite 6.3+. ' \
              'Please use katello-restore instead.'
        abort(msg)
      end

      add_steps_with_context(Checks::Restore::ValidateBackup,
                             Procedures::Restore::Confirmation,
                             Checks::Restore::ValidateHostname,
                             Procedures::Selinux::SetFileSecurity,
                             Procedures::Restore::Configs,
                             Procedures::Restore::InstallerReset,
                             Procedures::Service::Stop,
                             Procedures::Restore::ExtractFiles,
                             Procedures::Restore::DropDatabases,
                             Procedures::Restore::PgGlobalObjects,
                             Procedures::Restore::PostgresDumps,
                             Procedures::Restore::MongoDump,
                             Procedures::Pulp::Migrate,
                             Procedures::Service::Start,
                             Procedures::Service::DaemonReload)
    end
    # rubocop:enable Metrics/MethodLength

    def set_context_mapping
      context.map(:backup_dir,
                  Checks::Restore::ValidateBackup => :backup_dir,
                  Checks::Restore::ValidateHostname => :backup_dir,
                  Procedures::Restore::Configs => :backup_dir,
                  Procedures::Restore::DropDatabases => :backup_dir,
                  Procedures::Restore::PgGlobalObjects => :backup_dir,
                  Procedures::Restore::PostgresDumps => :backup_dir,
                  Procedures::Restore::ExtractFiles => :backup_dir,
                  Procedures::Restore::MongoDump => :backup_dir)

      context.map(:incremental_backup,
                  Procedures::Selinux::SetFileSecurity => :incremental_backup,
                  Procedures::Restore::InstallerReset => :incremental_backup)
    end
  end
end
