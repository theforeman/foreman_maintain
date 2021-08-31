require 'procedures/backup/snapshot/mount_base'
module Procedures::Backup
  module Snapshot
    class MountPulp < MountBase
      metadata do
        description 'Create and mount snapshot of Pulp data'
        tags :backup
        MountBase.common_params(self)
        param :skip, 'Skip Pulp content during backup'
        confine do
          feature(:pulp2) || feature(:pulpcore_database)
        end
      end

      def run
        skip if @skip
        with_spinner('Creating snapshot of Pulp') do |spinner|
          current_pulp_feature.with_marked_directory(current_pulp_feature.pulp_data_dir) do
            lv_info = get_lv_info(current_pulp_feature.pulp_data_dir)
            create_lv_snapshot('pulp-snap', @block_size, lv_info[0])
            spinner.update("Mounting snapshot of Pulp on #{mount_location('pulp')}")
            mount_snapshot('pulp', lv_info[1])
          end
        end
      end

      def current_pulp_feature
        feature(:pulp2) || feature(:pulpcore_database)
      end
    end
  end
end
