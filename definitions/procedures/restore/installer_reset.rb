module Procedures::Restore
  class InstallerReset < ForemanMaintain::Procedure
    metadata do
      description 'Run installer reset'

      param :incremental_backup,
            'Is the backup incremental?'
    end

    def run
      with_spinner('Resetting') do |spinner|
        if @incremental_backup
          spinner.update('Skipping installer reset for incremental update')
        else
          spinner.update('Installer reset')
          execute!(installer_cmd)
        end
      end
    end

    def installer_cmd
      installer = "yes | #{feature(:installer).installer_command} "
      installer << "--scenario #{feature(:installer).scenario_name} -v --reset"
      if feature(:instance).foreman_proxy_with_content?
        installer << ' --foreman-proxy-register-in-foreman false'
      end

      # We always disable system checks to avoid unnecessary errors. The installer should have
      # already ran since this is to be run on an existing system, which means installer checks
      # has already been skipped
      if feature(:foreman_proxy) &&
         feature(:foreman_proxy).with_content? &&
         check_min_version('katello-installer-base', '3.2.0')
        installer << ' --disable-system-checks'
      end
      installer
    end
  end
end
