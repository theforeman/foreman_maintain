module ForemanMaintain::Scenarios
  module VersionLocking
    class Status < ForemanMaintain::Scenario
      metadata do
        label :version_locking_status
        description 'detection of status of package version locking'
        manual_detection
      end

      def compose
        add_step(Procedures::Packages::LockingStatus)
      end
    end

    class Unlock < ForemanMaintain::Scenario
      metadata do
        label :version_locking_unlock
        description 'unlocking of package versions'
        manual_detection
      end

      def compose
        add_step(Procedures::Packages::UnlockVersions)
      end
    end

    class Lock < ForemanMaintain::Scenario
      metadata do
        label :version_locking_lock
        description 'locking of package versions'
        manual_detection
      end

      def compose
        add_step(Procedures::Packages::LockVersions)
      end
    end
  end
end
