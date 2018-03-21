module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    def run
      execute!("LANG=en_US.utf-8 #{installer_command} #{upgrade_command?}", :interactive => true)
    end

    private

    def upgrade_command?
      if package_version('satellite-installer') || package_version('katello-installer')
        '--upgrade'
      end
    end

    def installer_command
      if feature(:downstream)
        if feature(:downstream).current_minor_version <= '6.1'
          'katello-installer'
        else
          'satellite-installer'
        end
      else
        'foreman-installer'
      end
    end
  end
end
