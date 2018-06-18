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
    assert(
      !rhsm_hostname_eql_hostname?,
      notification_message,
      :next_steps => [
        Procedures::KnowledgeBaseArticle.new(:doc => 'migrate_self_registered_satellite_63')
      ]
    )
  end

  def notification_message
    <<-MESSAGE.strip_heredoc
      Satellite is self registered.
      Self registered satellite are not supported as of Satellite version 6.3.
      Please follow steps to migrate.
    MESSAGE
  end

  def rhsm_hostname
    execute("grep '\\bhostname\\b' < #{rhsm_conf_file}  | grep -v '^#'").sub(/.*?=/, '').strip
  end

  def rhsm_conf_file
    '/etc/rhsm/rhsm.conf'
  end

  def rhsm_hostname_eql_hostname?
    rhsm_hostname.casecmp(hostname).zero?
  end
end
