class Checks::SystemRegistration < ForemanMaintain::Check
  metadata do
    label :verify_self_registration
    description 'Check whether system is self-registered or not'
    tags :default

    confine do
      feature(:instance).downstream
    end
  end

  def run
    assert(!rhsm_hostname_eql_hostname?, 'System is self registered',
      {
        :warn => true,
        :next_steps => [Procedures::KnowledgeBaseArticle.new(:doc => 'self_registered')],
      })
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
