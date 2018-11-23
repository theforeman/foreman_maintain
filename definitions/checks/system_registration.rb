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
      rhsm_hostname.downcase != hostname.downcase,
      notification_message,
      :next_steps => steps_to_follow
    )
  end

  def steps_to_follow
    if feature(:instance).downstream.current_minor_version == '6.3'
      [Procedures::KnowledgeBaseArticle.new(:doc => 'migrate_self_registered_satellite_63')]
    else
      []
    end
  end

  def notification_message
    product_name = feature(:instance).product_name

    msg = "\n#{product_name} is self registered."
    msg += "\nSelf registered #{product_name} is not supported from version 6.3 onwards."
    if feature(:instance).downstream.current_minor_version == '6.3'
      msg += "\nPlease follow steps to migrate."
    end
    msg
  end

  def rhsm_hostname
    execute("grep '\\bhostname\\b' < #{rhsm_conf_file}  | grep -v '^#'").sub(/.*?=/, '').strip
  end

  def rhsm_conf_file
    '/etc/rhsm/rhsm.conf'
  end
end
