module Checks::RemoteExecution
  class VerifySettingsFileAlreadyExists < ForemanMaintain::Check
    metadata do
      description 'Check to verify remote_execution_ssh settings already exist'

      confine do
        feature(:instance).downstream &&
          feature(:instance).downstream.current_minor_version == '6.2' &&
          find_package('tfm-rubygem-smart_proxy_dynflow_core') &&
          file_exists?('/etc/smart_proxy_dynflow_core')
      end
    end

    def run
      if file_exists?(settingd_dir_path)
        symlinks = find_symlinks(settingd_dir_path)
        assert(
          symlinks.empty?,
          failure_msg(settingd_dir_path, symlinks),
          :next_steps => [
            Procedures::RemoteExecution::RemoveExistingSettingsd.new(
              :dirpath => settingd_dir_path
            )
          ]
        )
      end
    end

    private

    def failure_msg(dir_path, symlinks)
      'Settings related to remote_execution_ssh are already present'\
      " under #{dir_path} and " \
      "\nit would conflict with the installer from the next version." \
      "\nsymlinks available - #{symlinks.join(', ')}"
    end

    def settingd_dir_path
      '/etc/smart_proxy_dynflow_core/settings.d'
    end
  end
end
