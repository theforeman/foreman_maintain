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
      installer << '-v --reset '
      if feature(:instance).foreman_proxy_with_content?
        installer << '--foreman-proxy-register-in-foreman false '
      end

      # We always disable system checks to avoid unnecessary errors. The installer should have
      # already ran since this is to be run on an existing system, which means installer checks
      # has already been skipped
      current_proxy_feature = feature(:instance).proxy_feature
      if current_proxy_feature &&
         current_proxy_feature.with_content? &&
         check_min_version('katello-installer-base', '3.2.0')
        installer << '--disable-system-checks '
      end
      installer
    end
  end
end
