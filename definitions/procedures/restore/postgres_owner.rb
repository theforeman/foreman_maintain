module Procedures::Restore
  class PostgresOwner < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemHelpers
    metadata do
      description 'Make postgres owner of backup directory'

      param :backup_dir,
        'Path to backup directory',
        :required => true
    end

    def run
      if feature(:instance).foreman_proxy_with_content?
        FileUtils.chown(nil, 'postgres', @backup_dir)
      end
    end
  end
end
