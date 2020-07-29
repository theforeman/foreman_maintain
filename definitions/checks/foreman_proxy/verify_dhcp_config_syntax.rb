module Checks::ForemanProxy
  class VerifyDhcpConfigSyntax < ForemanMaintain::Check
    metadata do
      description 'Check for verifying syntax for ISP DHCP configurations'
      tags :default
      confine do
        feature(:foreman_proxy) &&
          feature(:foreman_proxy).features.include?('dhcp') &&
          feature(:foreman_proxy).dhcp_isc_provider?
      end
    end

    def run
      if feature(:foreman_proxy).dhcpd_conf_exist?
        success = feature(:foreman_proxy).valid_dhcp_configs?
        assert(success, 'Please check and verify DHCP configurations.')
      else
        fail! "Couldn't find configuration file at #{feature(:foreman_proxy).dhcpd_config_file}"
      end
    end
  end
end
