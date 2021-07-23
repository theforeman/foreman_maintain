module ForemanMaintain
  module Concerns
    module PulpCommon
      def data_dir
        '/var/lib/pulp'
      end

      def exclude_from_backup
        # For pulp2:
        # Exclude /var/lib/pulp/katello-export and /var/lib/pulp/cache
        # since the tar is run from /var/lib/pulp, list subdir paths only
        # For pulp3/pulpcore:
        pulp2_dirs = %w[katello-export cache]
        # For pulp3/pulpcore:
        # Only need to backup media directory of /var/lib/pulp
        # All below directories and their contents are regenerated on installer run
        pulpcore_dirs = %w[assets exports imports sync_imports tmp]
        pulp2_dirs + pulpcore_dirs
      end
    end
  end
end
