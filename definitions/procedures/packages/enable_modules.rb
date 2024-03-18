module Procedures::Packages
  class EnableModules < ForemanMaintain::Procedure
    metadata do
      description 'Enable the given stream modules'
      confine do
        package_manager.instance_of?(ForemanMaintain::PackageManager::Dnf)
      end
      param :module_names, 'Module names', :array => true, :required => true
      advanced_run false
    end

    def run
      package_manager.enable_module(@module_names.join(' '))
    end
  end
end
