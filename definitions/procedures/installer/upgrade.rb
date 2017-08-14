module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    def run
      execute!("#{installer_command} --upgrade", :interactive => true)
    end

    private

    def installer_command
      if package_version('satellite-installer')
        'satellite-installer'
      elsif package_version('katello-installer')
        'katello-installer'
      else
        'foreman-installer'
      end
    end
  end
end
