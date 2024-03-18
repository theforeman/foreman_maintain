require 'test_helper'

describe Procedures::Packages::EnableModules do
  include DefinitionsTestHelper

  subject do
    Procedures::Packages::EnableModules.new(:module_names => ['testmodule:el8'])
  end

  before do
    ForemanMaintain.stubs(:el?).returns(true)
    PackageManagerTestHelper.mock_package_manager(ForemanMaintain::PackageManager::Dnf.new)
  end

  it 'enables modules' do
    enable_command = 'dnf -y --disableplugin=foreman-protector module enable testmodule:el8'

    ForemanMaintain::Utils::SystemHelpers.expects(:'execute!').with(enable_command,
      :interactive => false, :valid_exit_statuses => [0]).returns(0)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
