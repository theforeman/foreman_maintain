require 'test_helper'

describe Procedures::Packages::SwitchModules do
  include DefinitionsTestHelper

  subject do
    Procedures::Packages::SwitchModules.new(:module_names => ['testmodule:el8'])
  end

  before do
    PackageManagerTestHelper.mock_package_manager(ForemanMaintain::PackageManager::Dnf.new)
  end

  it 'switches modules' do
    ForemanMaintain.package_manager.expects(:switch_module).with('testmodule:el8')
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
