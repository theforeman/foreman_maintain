module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    def run
      execute!("#{installer_command}#{upgrade_option}", :interactive => true)
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

    def upgrade_option
      ' --upgrade' if feature(:katello)
    end
  end
end
