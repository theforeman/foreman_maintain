class Checks::SystemRegistration < ForemanMaintain::Check
  metadata do
    label :verify_self_registration
    description 'Check whether system is self-registered or not'
    tags :default

    confine do
      file_exists?('/etc/rhsm/rhsm.conf') && feature(:instance).downstream
    end
  end

  def run
    if rhsm_hostname_eql_hostname?
      if feature(:downstream)
        notification_message = <<-MESSAGE
  Satellite is self registered

  Self registered satellite won't be supported as of Satellite version 6.3. Please follow following documentation to resolve.

  https://access.redhat.com/documentation/en-us/red_hat_satellite/6.3/html/installation_guide/preparing_your_environment_for_installation#system_requirements

  https://access.redhat.com/documentation/en-us/red_hat_satellite/6.3/html/upgrading_and_updating_red_hat_satellite/upgrading_red_hat_satellite#migrating_a_self_registered_satellite
    MESSAGE
        fail!(notification_message)
      else
        fail! 'System is self registered'
      end
    end
  end

  def rhsm_hostname
    execute("grep '\\bhostname\\b' < #{rhsm_conf_file}  | grep -v '^#'").sub(/.*?=/, '').strip
  end

  def rhsm_conf_file
    '/etc/rhsm/rhsm.conf'
  end

  def rhsm_hostname_eql_hostname?
    @result ||= rhsm_hostname.casecmp(hostname).zero?
  end
end
