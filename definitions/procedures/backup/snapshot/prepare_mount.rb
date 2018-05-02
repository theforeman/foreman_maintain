module Procedures::Backup
  module Snapshot
    class PrepareMount < ForemanMaintain::Procedure
      metadata do
        description 'Prepare mount point for the snapshot'
        tags :backup
        param :mount_dir, 'Snapshot mount directory', :required => true
      end

      def run
        logger.debug("Creating snap dir: #{@mount_dir}")
        FileUtils.mkdir_p @mount_dir
      end
    end
  end
end
