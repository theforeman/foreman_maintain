module Checks::Backup
  class DirectoryReady < ForemanMaintain::Check
    metadata do
      description 'Check if the directory exists and is writable'
      tags :backup
      manual_detection
      param :backup_dir, 'Directory where to backup to', :required => true
      param :preserve_dir, 'Directory where to backup to', :flag => true, :default => false
      param :postgres_access, 'Whether the postgres user needs access', :flag => true,
        :default => false
    end

    def run
      assert(File.directory?(@backup_dir), "Backup directory (#{@backup_dir}) does not exist.")
      if feature(:instance).postgresql_local? && @postgres_access
        result = system("runuser - postgres -c 'test -w #{@backup_dir}'")
        assert(result, "Postgres user needs write access to the backup directory \n" \
          "Please allow the postgres user write access to #{@backup_dir}" \
          ' or choose another directory.')
      end
    end
  end
end
