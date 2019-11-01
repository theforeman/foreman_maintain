module Procedures::Packages
  class LockVersions < ForemanMaintain::Procedure
    metadata do
      description 'Lock packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      package_manager.lock_versions
    end
  end
end
