require 'test_helper'

describe Procedures::Backup::PrepareDirectory do
  include DefinitionsTestHelper

  let(:backup_dir) { '/mnt/backup' }

  context 'with default params' do
    subject do
      Procedures::Backup::PrepareDirectory.new(:backup_dir => backup_dir)
    end

    it 'creates backup directory for local DB' do
      assume_feature_present(:instance, :postgresql_local? => true)

      FileUtils.expects(:mkdir_p).with(backup_dir).once
      FileUtils.expects(:chmod_R).with(0o770, backup_dir).once
      FileUtils.expects(:chown_R).with(nil, 'postgres', backup_dir).once

      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
    end

    it 'does not fail when chown to postgres fails' do
      assume_feature_present(:instance, :postgresql_local? => true)

      FileUtils.expects(:mkdir_p).with(backup_dir).once
      FileUtils.expects(:chmod_R).with(0o770, backup_dir).once
      FileUtils.expects(:chown_R).with(nil, 'postgres', backup_dir).once.raises(Errno::EPERM)

      result = run_procedure(subject)
      assert result.warning?, 'the procedure was expected to warn'

      warn_msg = <<~MSG
        /mnt/backup could not be made readable by the 'postgres' user.
        This won't affect the backup procedure, but you have to ensure that
        the 'postgres' user can read the data during restore.
      MSG
      assert_equal warn_msg, result.output
    end

    it 'creates backup directory for remote DB' do
      assume_feature_present(:instance, :postgresql_local? => false)

      FileUtils.expects(:mkdir_p).with(backup_dir).once
      FileUtils.expects(:chmod_R).with(0o770, backup_dir).once
      FileUtils.expects(:chown_R).with(nil, 'postgres', backup_dir).never

      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
    end
  end

  context 'with preserve_dir=>true' do
    subject do
      Procedures::Backup::PrepareDirectory.new(:backup_dir => backup_dir, :preserve_dir => true)
    end

    it 'does not create backup directory for local DB' do
      assume_feature_present(:instance, :postgresql_local? => true)

      FileUtils.expects(:mkdir_p).with(backup_dir).never
      FileUtils.expects(:chmod_R).with(0o770, backup_dir).never
      FileUtils.expects(:chown_R).with(nil, 'postgres', backup_dir).never

      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
    end

    it 'does not create backup directory for remote DB' do
      assume_feature_present(:instance, :postgresql_local? => false)

      FileUtils.expects(:mkdir_p).with(backup_dir).never
      FileUtils.expects(:chmod_R).with(0o770, backup_dir).never
      FileUtils.expects(:chown_R).with(nil, 'postgres', backup_dir).never

      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
    end
  end
end
