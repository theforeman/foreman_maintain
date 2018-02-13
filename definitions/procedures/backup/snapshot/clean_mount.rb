module Procedures::Backup
  module Snapshot
    class CleanMount < ForemanMaintain::Procedure
      metadata do
        description 'Remove the snapshot mount points'
        tags :backup
        param :mount_dir, 'Snapshot mount directory', :required => true
      end

      def run
        %w[pulp mongodb pgsql].each do |database|
          mount_point = File.join(@mount_dir, database)

          if File.exist?(mount_point) && !execute("mount|grep #{mount_point}").empty?
            execute("umount #{mount_point}")
          end

          snapshot_location = get_lv_path("#{database}-snap")
          execute("lvremove #{snapshot_location} -f") unless snapshot_location.empty?
        end
      end
    end
  end
end
