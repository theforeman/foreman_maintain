module Procedures::Packages
  class LockVersions < ForemanMaintain::Procedure
    metadata do
      for_feature :package_manager
      description 'Lock packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      feature(:package_manager).lock_versions
    end
  end
end
