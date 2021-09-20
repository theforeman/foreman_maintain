require 'test_helper'

describe Checks::Restore::ValidateInterfaces do
  include DefinitionsTestHelper

  subject do
    Checks::Restore::ValidateInterfaces.new(:backup_dir => '.')
  end

  it 'passes when no invalid interfaces found' do
    ForemanMaintain::Utils::Backup.any_instance.stubs(:validate_interfaces).returns({})
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when invalid interfaces found' do
    invalid = { 'dhcp' => { 'configured' => 'eth0' } }
    ForemanMaintain::Utils::Backup.any_instance.stubs(:validate_interfaces).returns(invalid)
    result = run_check(subject)
    refute result.success?, 'Check expected to fail'
    expected = 'The following features are enabled in the backup, '\
      "\nbut the system does not have the interfaces used by these features: dhcp (eth0)."
    assert_equal result.output, expected
  end
end
