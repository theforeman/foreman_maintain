module Checks::ForemanProxy
  class VerifyDhcpConfigSyntax < ForemanMaintain::Check
    metadata do
      for_feature :foreman_proxy
      description 'Check for verifying syntax for ISP DHCP configurations'
      tags :default
      confine do
        file_exists?('/etc/dhcp/dhcpd.conf')
      end
    end

    def run
      success = feature(:foreman_proxy).valid_dhcp_configs?
      assert(success, 'Please check and verify DHCP configurations.')
    end
  end
end
