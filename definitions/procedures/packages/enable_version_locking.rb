module Procedures::Packages
  class EnableVersionLocking < ForemanMaintain::Procedure
    metadata do
      description 'Install and configure tools for version locking'
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      packages = feature(:package_manager).version_locking_packages
      feature(:package_manager).install(packages, :assumeyes => @assumeyes)
      unless feature(:package_manager).installed?(packages)
        raise "Unable to install some of the required dependences:  #{packages.join(' ')}"
      end
      feature(:package_manager).configure_version_locking
    end
  end
end
