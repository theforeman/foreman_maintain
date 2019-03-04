module Procedures::Packages
  class LockVersions < ForemanMaintain::Procedure
    metadata do
      for_feature :package_manager
      description 'Lock versions of Foreman-related packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      with_spinner('Collecting list of packages to lock') do |spinner|
        package_list = feature(:package_manager).foreman_related_packages
        spinner.update('Locking packages')
        feature(:package_manager).lock_versions(package_list)
      end
    end
  end
end
