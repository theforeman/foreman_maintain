module Checks::ForemanProxy
  class VerifyDhcpConfigSyntax < ForemanMaintain::Check
    metadata do
      description 'Check for verifying syntax for ISP DHCP configurations'
      tags :default
      confine do
        feature(:instance).proxy_feature
      end
    end

    def run
      current_proxy_feature = feature(:instance).proxy_feature
      if current_proxy_feature.features.include?('dhcp')
        if current_proxy_feature.dhcpd_conf_exist?
          success = current_proxy_feature.valid_dhcp_configs?
          assert(success, 'Please check and verify DHCP configurations.')
        else
          fail! "Couldn't find configuration file at #{current_proxy_feature.dhcpd_config_file}"
        end
      else
        skip 'DHCP feature is not enabled'
      end
    end
  end
end
