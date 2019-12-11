require 'procedures/backup/snapshot/mount_base'
module Procedures::Backup
  module Snapshot
    class MountPulp < MountBase
      metadata do
        description 'Create and mount snapshot of Pulp data'
        tags :backup
        for_feature :pulp2
        MountBase.common_params(self)
        param :skip, 'Skip Pulp content during backup'
      end

      def run
        skip if @skip
        with_spinner('Creating snapshot of Pulp') do |spinner|
          feature(:pulp2).with_marked_directory(feature(:pulp2).data_dir) do
            lv_info = get_lv_info(feature(:pulp2).data_dir)
            create_lv_snapshot('pulp-snap', @block_size, lv_info[0])
            spinner.update("Mounting snapshot of Pulp on #{mount_location('pulp')}")
            mount_snapshot('pulp', lv_info[1])
          end
        end
      end
    end
  end
end
