module Procedures::Packages
  class UnlockVersions < ForemanMaintain::Procedure
    metadata do
      description 'Unlock packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      package_manager.unlock_versions
    end
  end
end
