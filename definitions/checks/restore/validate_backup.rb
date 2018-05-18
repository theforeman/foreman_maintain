require 'foreman_maintain/utils/backup'

module Checks::Restore
  class ValidateBackup < ForemanMaintain::Check
    metadata do
      description 'Validate backup has appropriate files'

      param :backup_dir,
            'Path to backup directory',
            :required => true
      manual_detection
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      assert(backup.valid_backup?, valid_backup_message(backup))
    end

    def valid_backup_message(backup)
      message = "\n"
      message += "The given directory does not contain the required files or has too many files\n\n"
      message += "All backup directories contain: #{backup.standard_files.join(', ')}\n"
      message += required_files(backup)
      message += 'Including pulp_data.tar is optional and '
      message += "will restore pulp data to the filesystem if included.\n\n"
      message += "Only the following files were found: #{backup.present_files.join(', ')}\n"
      message
    end

    def required_files(backup)
      message = ''
      message += if feature(:instance).foreman_proxy_with_content?
                   required_fpc_files(backup)
                 elsif feature(:katello)
                   required_katello_files(backup)
                 else
                   required_foreman_files(backup)
                 end
      message
    end

    def required_katello_files(backup)
      backup_files_message(
        backup.katello_online_files.join(', '),
        backup.katello_offline_files.join(', '),
        [backup.katello_online_files + backup.katello_offline_files].join(', ')
      )
    end

    def required_fpc_files(backup)
      backup_files_message(
        backup.fpc_online_files.join(', '),
        backup.fpc_offline_files.join(', '),
        [backup.fpc_online_files + backup.fpc_offline_files].join(', ')
      )
    end

    def required_foreman_files(backup)
      backup_files_message(
        backup.foreman_online_files.join(', '),
        backup.foreman_offline_files.join(', '),
        [backup.foreman_online_files + backup.foreman_offline_files].join(', ')
      )
    end

    def backup_files_message(online_files, offline_files, logical_files)
      message = ''
      message += 'An online or remote database backup directory contains: '
      message += "#{online_files}\n"
      message += 'An offline backup directory contains: '
      message += "#{offline_files}\n"
      message += 'A logical backup directory contains: '
      message += "#{logical_files}\n"
      message
    end
  end
end
