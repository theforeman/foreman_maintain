require 'test_helper'

describe Checks::Restore::ValidatePostgresqlDumpPermissions do
  include DefinitionsTestHelper

  subject do
    Checks::Restore::ValidatePostgresqlDumpPermissions.new(:backup_dir => '.')
  end

  before do
    file_map = {
      :foreman_dump => { :present => true, :path => '/nonexistant/foreman.dump' },
      :candlepin_dump => { :present => true, :path => '/nonexistant/candlepin.dump' },
      :pulpcore_dump => { :present => true, :path => '/nonexistant/pulpcore.dump' },
    }
    ForemanMaintain::Utils::Backup.any_instance.stubs(:file_map).returns(file_map)
  end

  it 'passes when backup is offline and DB is local' do
    assume_feature_present(:instance, :postgresql_local? => true)
    ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(false)
    subject.stubs(:system).returns(true)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'passes when backup is offline and DB is remote' do
    assume_feature_present(:instance, :postgresql_local? => false)
    ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(false)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'passes when the backup is online and the DB is remote' do
    assume_feature_present(:instance, :postgresql_local? => false)
    ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(true)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'passes when the backup is online and the DB is local and files are readable' do
    assume_feature_present(:instance, :postgresql_local? => true)
    ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(true)
    subject.stubs(:system).returns(true)
    result = run_check(subject)
    assert result.success?, 'Check expected to succeed'
  end

  it 'fails when the backup is online and the DB is local and files are not readable' do
    assume_feature_present(:instance, :postgresql_local? => true)
    ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(true)
    subject.stubs(:system).returns(false)
    result = run_check(subject)
    refute result.success?, 'Check expected to fail'
    expected = "The 'postgres' user needs read access to the following files:\n" \
      "/nonexistant/candlepin.dump\n/nonexistant/foreman.dump\n/nonexistant/pulpcore.dump"
    assert_equal result.output, expected
  end

  it 'fails when the backup is online and the DB is local and one file is not readable' do
    assume_feature_present(:instance, :postgresql_local? => true)
    ForemanMaintain::Utils::Backup.any_instance.stubs(:online_backup?).returns(true)
    subject.stubs(:system).with("runuser - postgres -c 'test -r /nonexistant/candlepin.dump'").
      returns(false)
    subject.stubs(:system).with("runuser - postgres -c 'test -r /nonexistant/pulpcore.dump'").
      returns(true)
    subject.stubs(:system).with("runuser - postgres -c 'test -r /nonexistant/foreman.dump'").
      returns(true)
    result = run_check(subject)
    refute result.success?, 'Check expected to fail'
    expected = "The 'postgres' user needs read access to the following files:\n" \
      '/nonexistant/candlepin.dump'
    assert_equal result.output, expected
  end
end
