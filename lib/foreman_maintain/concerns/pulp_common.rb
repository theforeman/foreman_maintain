module ForemanMaintain
  module Concerns
    module PulpCommon
      def pulp_data_dir
        '/var/lib/pulp'
      end

      def exclude_from_backup
        # For pulp3/pulpcore:
        # Only need to backup media directory of /var/lib/pulp
        # All below directories and their contents are regenerated on installer run
        %w[assets exports imports sync_imports tmp]
      end
    end
  end
end
