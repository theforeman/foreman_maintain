module Checks
  class VersionLockingEnabled < ForemanMaintain::Check
    metadata do
      description 'Check if tooling for package locking is installed'
    end

    def run
      enabled = package_manager.version_locking_enabled?
      enable_locking = Procedures::Packages::EnableVersionLocking.new(:assumeyes => assumeyes?)
      assert(enabled, 'Tools for package version locking are not available on this system',
             :next_steps => enable_locking)
    end
  end
end
