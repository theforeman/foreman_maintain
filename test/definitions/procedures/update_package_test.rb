require 'test_helper'

describe Procedures::Packages::Update do
  include DefinitionsTestHelper

  it 'updates all packages' do
    ForemanMaintain.stubs(:el?).returns(true)
    procedure = Procedures::Packages::Update.new
    procedure.expects(:packages_action).with(:update, [],
      { :assumeyes => false, :yum_options => [] })
    result = run_procedure(procedure)
    assert result.success?
  end

  it 'updates all packages with --downloadonly' do
    ForemanMaintain.stubs(:el?).returns(true)
    procedure = Procedures::Packages::Update.new(:yum_options => ['--downloadonly'])
    procedure.expects(:packages_action).with(:update, [],
      { :assumeyes => false, :yum_options => ["--downloadonly"] })
    result = run_procedure(procedure)
    assert result.success?
  end
end
