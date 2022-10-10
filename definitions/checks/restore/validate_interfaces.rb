require 'foreman_maintain/utils/backup'

module Checks::Restore
  class ValidateInterfaces < ForemanMaintain::Check
    metadata do
      description 'Validate network interfaces match the backup'

      param :backup_dir,
        'Path to backup directory',
        :required => true
      manual_detection
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      invalid_interfaces = backup.validate_interfaces
      msg = 'The following features are enabled in the backup, '\
        "\nbut the system does not have the interfaces used by these features: "
      msg << invalid_interfaces.map { |k, v| "#{k} (#{v['configured']})" }.join(', ')
      msg << '.'
      assert(backup.validate_interfaces.empty?, msg)
    end
  end
end
