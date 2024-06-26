require 'test_helper'

describe Checks::Backup::IncrementalParentType do
  include DefinitionsTestHelper

  context 'without incremental_dir' do
    subject do
      Checks::Backup::IncrementalParentType.new
    end

    it 'passes without performing any checks' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).never
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end
  end

  context 'for offline backup with local PostreSQL tarballs' do
    subject do
      Checks::Backup::IncrementalParentType.new(:incremental_dir => '.', :online_backup => false,
        :sql_tar => true)
    end

    it 'passes when existing backup is offline with tarballs' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(false)
      ForemanMaintain::Utils::Backup.any_instance.expects(:sql_tar_files_exist?).returns(true)
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end

    it 'fails when existing backup is online' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(true)
      result = run_check(subject)
      refute result.success?, 'Check expected to fail'
      expected = 'The existing backup is an online backup, but an offline backup was requested.'
      assert_equal expected, result.output
    end

    it 'fails when existing backup uses dumps' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(false)
      ForemanMaintain::Utils::Backup.any_instance.expects(:sql_tar_files_exist?).returns(false)
      result = run_check(subject)
      refute result.success?, 'Check expected to fail'
      expected = 'The existing backup has PostgreSQL as a dump, '\
        'but the new one will have a tarball.'
      assert_equal expected, result.output
    end
  end

  context 'for offline backup with remote PostgreSQL dumps' do
    subject do
      Checks::Backup::IncrementalParentType.new(:incremental_dir => '.', :online_backup => false,
        :sql_tar => false)
    end

    it 'passes when existing backup is offline' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(false)
      ForemanMaintain::Utils::Backup.any_instance.expects(:sql_tar_files_exist?).returns(false)
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end

    it 'fails when existing backup is online' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(true)
      result = run_check(subject)
      refute result.success?, 'Check expected to fail'
      expected = 'The existing backup is an online backup, but an offline backup was requested.'
      assert_equal expected, result.output
    end

    it 'fails when existing backup uses psql_data.tar' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(false)
      ForemanMaintain::Utils::Backup.any_instance.expects(:sql_tar_files_exist?).returns(true)
      result = run_check(subject)
      refute result.success?, 'Check expected to fail'
      expected = 'The existing backup has PostgreSQL as a tarball, '\
        'but the new one will have a dump.'
      assert_equal expected, result.output
    end
  end

  context 'for online backup' do
    subject do
      Checks::Backup::IncrementalParentType.new(:incremental_dir => '.', :online_backup => true)
    end

    it 'passes when existing backup is online' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(true)
      result = run_check(subject)
      assert result.success?, 'Check expected to succeed'
    end

    it 'fails when existing backup is offline' do
      ForemanMaintain::Utils::Backup.any_instance.expects(:online_backup?).returns(false)
      result = run_check(subject)
      refute result.success?, 'Check expected to fail'
      expected = 'The existing backup is an offline backup, but an online backup was requested.'
      assert_equal expected, result.output
    end
  end
end
