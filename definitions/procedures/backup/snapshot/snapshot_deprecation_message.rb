module Procedures::Backup
  module Snapshot
    class SnapshotDeprecationMessage < ForemanMaintain::Procedure
      metadata do
        description 'Snapshot backups are deprecated'
        tags :backup
      end

      def run
        set_warn('Snapshot backups are deprecated and will be removed in a future version.')
      end
    end
  end
end
