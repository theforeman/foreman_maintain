require 'uri'
class Checks::CheckHammerConfig < ForemanMaintain::Check
  metadata do
    label :check_hammer_config
    description 'Check if hammer configuration file is using FQDN of system'
    tags :pre_upgrade
    confine do
      feature(:downstream)
    end
  end

  def run
    with_spinner('Checking hostname of hammer configuration') do
      assert(compare_hostname?, 'The :host parameter configured for hammer should not be'\
        " 'localhost'")
    end
  end

  def hammer_host_url
    if feature(:hammer).configuration[:foreman][:host]
      URI.parse(feature(:hammer).configuration[:foreman][:host]).host
    end
  end

  def compare_hostname?
    return hammer_host_url != 'localhost' unless hammer_host_url.nil?

    true
  end
end
