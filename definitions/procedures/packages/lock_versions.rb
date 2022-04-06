module Procedures::Packages
  class LockVersions < ForemanMaintain::Procedure
    metadata do
      description 'Lock packages'
      confine do
        package_manager.version_locking_supported?
      end
    end

    def run
      package_manager.lock_versions
    end
  end
end
