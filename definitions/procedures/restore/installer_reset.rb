module Procedures::Restore
  class InstallerReset < ForemanMaintain::Procedure
    metadata do
      description 'Run installer reset'
    end

    def run
      with_spinner('Installer reset') do
        execute!(installer_cmd)
      end
    end

    def installer_cmd
      installer = "yes | #{feature(:installer).installer_command} "
      installer << '-v --reset-data '
      if feature(:instance).foreman_proxy_with_content?
        installer << '--foreman-proxy-register-in-foreman false '
      end

      installer
    end
  end
end
