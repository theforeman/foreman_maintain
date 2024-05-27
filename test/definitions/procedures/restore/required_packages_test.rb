require 'test_helper'

describe Procedures::Restore::RequiredPackages do
  include DefinitionsTestHelper

  subject do
    Procedures::Restore::RequiredPackages.new(:backup_dir => '.')
  end

  it 'installs puppetserver if it was in the backup' do
    ForemanMaintain::Utils::Backup.any_instance.stubs(:with_puppetserver?).returns(true)
    ForemanMaintain.package_manager.expects(:install).
      with(['puppetserver'], assumeyes: true).once
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end

  it 'doesnt install puppetserver if it wasnt in the backup' do
    ForemanMaintain::Utils::Backup.any_instance.stubs(:with_puppetserver?).returns(false)
    ForemanMaintain.package_manager.expects(:install).
      with(['puppetserver'], assumeyes: true).never
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end

  it 'doesnt install anything if it was not in the backup' do
    ForemanMaintain::Utils::Backup.any_instance.stubs(:with_puppetserver?).returns(false)
    ForemanMaintain.package_manager.expects(:install).never
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
