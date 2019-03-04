module ForemanMaintain::PackageManager
  # rubocop:disable Lint/UnusedMethodArgument
  class Base
    def foreman_related_packages
      raise NotImplementedError
    end

    # list of packages providing the version locking
    def version_locking_packages
      raise NotImplementedError
    end

    # check tools are installed and enabled
    def version_locking_enabled?
      raise NotImplementedError
    end

    # make sure the version locking tools are configured
    # we can assume it is already installed
    def configure_version_locking
      raise NotImplementedError
    end

    # are the packages installed on the system?
    def installed?(packages)
      raise NotImplementedError
    end

    # find installed package and return full nvra or nil
    def find_installed_package(name)
      raise NotImplementedError
    end

    # install package
    def install(packages, assumeyes: false)
      raise NotImplementedError
    end

    # update package
    def update(packages = [], assumeyes: false)
      raise NotImplementedError
    end

    # prevent listed packages from update
    def lock_versions(package_list)
      raise NotImplementedError
    end

    # allow all packages we previously locked to update
    def unlock_versions
      raise NotImplementedError
    end

    # check if packages are locked
    def versions_locked?
      raise NotImplementedError
    end

    # clean the package manager cache
    def clean_cache
      raise NotImplementedError
    end

    private

    def sys
      ForemanMaintain::Utils::SystemHelpers
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
