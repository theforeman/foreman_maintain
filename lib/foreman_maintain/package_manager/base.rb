module ForemanMaintain::PackageManager
  class Base
    # confirms that Package Manager supports the locking mechanism
    def version_locking_supported?
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

    # remove package
    def remove(packages, assumeyes: false)
      raise NotImplementedError
    end

    # update package
    def update(packages = [], assumeyes: false)
      raise NotImplementedError
    end

    # prevent selected packages from update or install
    def lock_versions
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

    # list all files not owned by installed package
    def files_not_owned_by_package(directory)
      raise NotImplementedError
    end

    # confirms that Package Manager supports modules
    def modules_supported?
      false
    end

    def sys
      ForemanMaintain::Utils::SystemHelpers
    end
  end
end
