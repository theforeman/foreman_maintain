module Procedures::Packages
  class EnableVersionLocking < ForemanMaintain::Procedure
    metadata do
      description 'Install and configure tools for version locking'
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      installed_fm_packages = []
      ['satellite-maintain', 'rubygem-foreman_maintain'].each do |pkg|
        installed_fm_packages << find_package(pkg)
      end
      package_manager.reinstall(installed_fm_packages, :assumeyes => @assumeyes)
    end
  end
end
