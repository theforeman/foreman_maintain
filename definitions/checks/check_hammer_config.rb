require 'uri'
class Checks::CheckHammerConfig < ForemanMaintain::Check
  metadata do
    label :check_hammer_config
    description 'Check if hammer configuration file is using FQDN of system'
    tags :post_upgrade
    confine do
      feature(:downstream)
    end
  end

  def run
    msg = "\nMake sure :host: <system_fqdn> is included in "\
           'your ~/.hammer/cli.modules.d/foreman.yml or'\
           "\nin /etc/hammer/cli.modules.d/foreman.yml file."
    with_spinner('Checking hostname of hammer configuration') do
      assert(compare_hostname?, "\nThe :host: parameter configured for hammer should not be"\
        " 'localhost'. #{msg}", :warn => true)
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
