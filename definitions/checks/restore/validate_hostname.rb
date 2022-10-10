require 'foreman_maintain/utils/backup'

module Checks::Restore
  class ValidateHostname < ForemanMaintain::Check
    metadata do
      description 'Validate hostname is the same as backup'

      param :backup_dir,
        'Path to backup directory',
        :required => true
      manual_detection
    end

    def run
      msg = 'The hostname in the backup does not match the hostname of the system'
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      assert(backup.validate_hostname?, msg)
    end
  end
end
