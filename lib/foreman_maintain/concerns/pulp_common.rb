module ForemanMaintain
  module Concerns
    module PulpCommon
      def pulp_data_dir
        '/var/lib/pulp'
      end

      def exclude_from_backup
        # Only need to backup media directory of /var/lib/pulp
        # All below directories and their contents are regenerated on installer run
        %w[assets exports imports sync_imports tmp]
      end

      def pulpcore_manager(command)
        "PULP_SETTINGS=/etc/pulp/settings.py runuser -u pulp -- pulpcore-manager #{command}"
      end
    end
  end
end
