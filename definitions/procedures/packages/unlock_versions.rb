module Procedures::Packages
  class UnlockVersions < ForemanMaintain::Procedure
    metadata do
      for_feature :package_manager
      description 'Unlock packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      feature(:package_manager).unlock_versions
    end
  end
end
