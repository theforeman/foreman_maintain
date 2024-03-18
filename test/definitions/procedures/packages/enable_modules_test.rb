require 'test_helper'

describe Procedures::Packages::EnableModules do
  include DefinitionsTestHelper

  subject do
    Procedures::Packages::EnableModules.new(:module_names => ['testmodule:el8'])
  end

  before do
    PackageManagerTestHelper.mock_package_manager(ForemanMaintain::PackageManager::Dnf.new)
  end

  it 'enables modules' do
    ForemanMaintain.package_manager.expects(:enable_module).with('testmodule:el8')
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
