require 'test_helper'

describe Procedures::Packages::Update do
  include DefinitionsTestHelper

  it 'updates all packages' do
    ForemanMaintain.stubs(:el?).returns(true)
    procedure = Procedures::Packages::Update.new
    procedure.expects(:packages_action).with(:update, [],
      { :assumeyes => false, :options => [], :download_only => false })
    result = run_procedure(procedure)
    assert result.success?
  end

  it 'updates all packages with --downloadonly' do
    ForemanMaintain.stubs(:el?).returns(true)
    procedure = Procedures::Packages::Update.new(:download_only => true)
    procedure.expects(:packages_action).with(:update, [],
      { :assumeyes => false, :options => [], :download_only => true })
    result = run_procedure(procedure)
    assert result.success?
  end
end
