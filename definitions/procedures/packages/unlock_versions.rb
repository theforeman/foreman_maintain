module Procedures::Packages
  class UnlockVersions < ForemanMaintain::Procedure
    metadata do
      description 'Unlock packages'
      confine do
        package_manager.version_locking_supported?
      end
    end

    def run
      package_manager.unlock_versions
    end
  end
end
