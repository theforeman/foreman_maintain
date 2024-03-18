require 'test_helper'

describe Procedures::Packages::EnableModules do
  include DefinitionsTestHelper

  subject do
    Procedures::Packages::EnableModules.new(:module_names => ['testmodule:el8'])
  end

  before do
    ForemanMaintain.stubs(:el?).returns(true)
  end

  it 'enables modules' do
    enable_command = 'dnf module enable testmodule:el8 -y'

    subject.expects(:'execute!').with(enable_command).returns(0)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
