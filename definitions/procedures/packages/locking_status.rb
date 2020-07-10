module Procedures::Packages
  class LockingStatus < ForemanMaintain::Procedure
    metadata do
      description 'Check status of version locking of packages'
      preparation_steps { [Checks::VersionLockingEnabled.new] }
    end

    def run
      check_automatic_locking
      check_version_locked
    end

    private

    def check_version_locked
      if package_manager.versions_locked?
        puts '  Packages are locked.'
      else
        puts '  Packages are not locked.'
        puts "  WARNING: When locking is disabled there is a risk of unwanted update\n" \
             "  of #{feature(:instance).product_name} and its components and possible " \
             'data inconsistency'
      end
    end

    def check_automatic_locking
      if feature(:installer).lock_package_versions_supported?
        if feature(:installer).lock_package_versions?
          puts '  Automatic locking of package versions is enabled in installer.'
        else
          puts '  Automatic locking of package versions is disabled in installer.'
        end
      else
        puts '  Automatic locking of package versions is not supported by installer.'
      end
    end
  end
end
