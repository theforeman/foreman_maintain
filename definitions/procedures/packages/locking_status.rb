module Procedures::Packages
  class LockingStatus < ForemanMaintain::Procedure
    metadata do
      for_feature :package_manager
      description 'Check status of version locking of Foreman-related packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      if feature(:package_manager).versions_locked?
        puts 'Packages are locked.'
      else
        puts 'Packages are not locked.'
      end
    end
  end
end
