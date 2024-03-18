module Procedures::Packages
  class SwitchModules < ForemanMaintain::Procedure
    metadata do
      description 'Switch the given stream modules'
      confine do
        package_manager.modules_supported?
      end
      param :module_names, 'Module names', :array => true, :required => true
      advanced_run false
    end

    def run
      package_manager.switch_module(@module_names.join(' '))
    end
  end
end
