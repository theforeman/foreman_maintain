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
      installer << reset_option
      if feature(:instance).foreman_proxy_with_content?
        installer << '--foreman-proxy-register-in-foreman false '
      end

      # We always disable system checks to avoid unnecessary errors. The installer should have
      # already ran since this is to be run on an existing system, which means installer checks
      # has already been skipped
      if feature(:foreman_proxy) &&
         feature(:foreman_proxy).with_content? &&
         check_max_version('foreman-installer', '3.4')
        installer << '--disable-system-checks '
      end
      installer
    end

    def reset_option
      if check_min_version('foreman', '2.2') || \
         check_min_version('foreman-proxy', '2.2')
        return '-v --reset-data '
      end

      '-v --reset '
    end
  end
end
