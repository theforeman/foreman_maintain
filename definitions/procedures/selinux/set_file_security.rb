module Procedures::Selinux
  class SetFileSecurity < ForemanMaintain::Procedure
    metadata do
      description 'Setting file security'

      param :incremental_backup,
        'Is the backup incremental?',
        :required => true
      manual_detection
      confine do
        File.directory?('/sys/fs/selinux')
      end
    end

    def run
      with_spinner('Restoring SELinux context') do |spinner|
        if @incremental_backup
          spinner.update('Skipping for incremental update')
        else
          execute!('restorecon -Rn /')
        end
      end
    end
  end
end
