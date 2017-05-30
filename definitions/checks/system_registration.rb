class Checks::SystemRegistration < ForemanMaintain::Check
  metadata do
    label :verify_self_registration
    description 'Check whether system is self-registered or not'
    tags :default
    after :disk_io

    confine do
      file_exists?('/etc/rhsm/rhsm.conf')
    end
  end

  def run
    if system_is_self_registerd?
      raise ForemanMaintain::Error::Warn, 'System is self registered'
    else
      puts 'System is not self registered'
    end
  end

  def system_is_self_registerd?
    rhsm_hostname.casecmp(hostname).zero?
  end

  def rhsm_hostname
    execute("grep '\\bhostname\\b' < #{rhsm_conf_file}  | grep -v '^#'").sub(/.*?=/, '').strip
  end

  def rhsm_conf_file
    '/etc/rhsm/rhsm.conf'
  end
end
