module Checks::ForemanProxyDhcp
  class VerifyDhcpConfigSyntax < ForemanMaintain::Check
    metadata do
      for_feature :foreman_proxy_dhcp
      description 'Check for verifying syntax for ISP DHCP configurations'
      tags :isp_dhcp_config_check
      confine do
        file_exists?('/etc/dhcp/dhcpd.conf')
      end
    end

    def run
      success = feature(:foreman_proxy_dhcp).valid_dhcp_configs?
      assert(success, 'Please check and verify DHCP configurations.')
    end
  end
end
