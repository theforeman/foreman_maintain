module Procedures::Backup
  class Clean < ForemanMaintain::Procedure
    metadata do
      description 'Clean up backup directory'
      tags :backup
      param :backup_dir, 'Directory where to backup to', :required => true
      param :preserve_dir, 'Directory where to backup to'
    end

    def run
      skip('Backup directory will be preserved') if @preserve_dir
      FileUtils.rm_rf @backup_dir
      logger.info("Backup directory #{@backup_dir} was removed.")
    end
  end
end
