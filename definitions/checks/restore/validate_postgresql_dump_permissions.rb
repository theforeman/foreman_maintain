module Checks::Restore
  class ValidatePostgresqlDumpPermissions < ForemanMaintain::Check
    metadata do
      description 'Validate permissions for PostgreSQL dumps'

      param :backup_dir,
        'Path to backup directory',
        :required => true
      manual_detection
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      if feature(:instance).postgresql_local?
        errors = []
        [:candlepin_dump, :foreman_dump, :pulpcore_dump].each do |dump|
          next unless backup.file_map[dump][:present]

          unless system("runuser - postgres -c 'test -r #{backup.file_map[dump][:path]}'")
            errors << backup.file_map[dump][:path]
          end
        end

        msg = "The 'postgres' user needs read access to the following files:\n"
        msg << errors.join("\n")
        assert(errors.empty?, msg)

      end
    end
  end
end
