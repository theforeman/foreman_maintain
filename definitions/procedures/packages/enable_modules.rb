module Procedures::Packages
  class EnableModules < ForemanMaintain::Procedure
    metadata do
      description 'Enable the given stream modules'
      confine do
        package_manager.class.name == 'ForemanMaintain::PackageManager::Dnf'
      end
      param :module_names, 'Module names', :array => true, :required => true
      param :assumeyes, 'Do not ask for confirmation'
      advanced_run false
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      dnf_option = assumeyes_val ? ' -y' : ''
      execute!("dnf module enable #{@module_names.join(' ')} #{dnf_option}")
    end
  end
end
