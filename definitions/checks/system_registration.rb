class Checks::SystemRegistration < ForemanMaintain::Check
  metadata do
    label :verify_self_registration
    description 'Check whether system is self-registered or not'
    tags :default

    confine do
      file_exist?('/etc/rhsm/rhsm.conf') &&
        !feature(:foreman_server) &&
        feature(:foreman_proxy)
    end
  end

  def run
    if rhsm_hostname_eql_hostname?
      warn! 'System is self registered'
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
