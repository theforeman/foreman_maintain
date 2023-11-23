module Procedures::Backup
  module Snapshot
    class MountBase < ForemanMaintain::Procedure
      metadata do
        advanced_run false
      end

      def self.common_params(context)
        context.instance_eval do
          param :mount_dir, 'Snapshot mount directory', :required => true
          param :block_size, 'Snapshot block size', :default => '2G'
        end
      end

      def mount_snapshot(database, lv_type)
        FileUtils.mkdir_p(mount_location(database))
        options = (lv_type == 'xfs') ? '-onouuid,ro' : '-oro'
        lv_name = "#{database}-snap"
        execute!("mount #{get_lv_path(lv_name)} #{mount_location(database)} #{options}")
      end

      def mount_location(database)
        File.join(@mount_dir, database)
      end
    end
  end
end
