module Procedures::Packages
  class EnableModules < ForemanMaintain::Procedure
    metadata do
      description 'Enable the given stream modules'
      confine do
        package_manager.class.name == 'ForemanMaintain::PackageManager::Dnf'
      end
      param :module_names, 'Module names', :array => true, :required => true
      advanced_run false
    end

    def run
      execute!("dnf module enable #{@module_names.join(' ')} -y")
    end
  end
end
