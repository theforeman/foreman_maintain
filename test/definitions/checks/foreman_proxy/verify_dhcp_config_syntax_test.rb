require 'test_helper'

describe Checks::ForemanProxy::VerifyDhcpConfigSyntax do
  include DefinitionsTestHelper

  subject do
    Checks::ForemanProxy::VerifyDhcpConfigSyntax.new
  end

  before do
    stub_foreman_proxy_config
  end

  it 'passes when no any error in syntax as well as DHCP subnets' do
    assume_feature_present(:foreman_proxy, :dhcpd_conf_exist? => true, :valid_dhcp_configs? => true,
                                           :dhcp_isc_provider? => true)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when failure either in syntax or in DHCP subnets' do
    assume_feature_present(:foreman_proxy, :dhcpd_conf_exist? => true,
                                           :valid_dhcp_configs? => false,
                                           :dhcp_isc_provider? => true)
    result = run_check(subject)
    assert result.fail?, 'Check expected to fail'
    assert_match 'Please check and verify DHCP configurations.', result.output
  end
end
