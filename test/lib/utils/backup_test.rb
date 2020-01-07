require 'test_helper'
require File.expand_path('../../../lib/foreman_maintain/utils/backup.rb',
                         File.dirname(__FILE__))

module ForemanMaintain
  describe Utils::Backup do
    subject { Utils::Backup }
    let(:katello_standard) do
      File.expand_path('../../files/backups/katello_standard', File.dirname(__FILE__))
    end
    let(:katello_standard_incremental) do
      File.expand_path('../../files/backups/katello_standard_incremental', File.dirname(__FILE__))
    end
    let(:katello_online) do
      File.expand_path('../../files/backups/katello_online', File.dirname(__FILE__))
    end
    let(:katello_logical) do
      File.expand_path('../../files/backups/katello_logical', File.dirname(__FILE__))
    end
    let(:foreman_standard) do
      File.expand_path('../../files/backups/foreman_standard', File.dirname(__FILE__))
    end
    let(:foreman_online) do
      File.expand_path('../../files/backups/foreman_online', File.dirname(__FILE__))
    end
    let(:foreman_logical) do
      File.expand_path('../../files/backups/foreman_logical', File.dirname(__FILE__))
    end
    let(:fpc_standard) do
      File.expand_path('../../files/backups/fpc_standard', File.dirname(__FILE__))
    end
    let(:fpc_online) do
      File.expand_path('../../files/backups/fpc_online', File.dirname(__FILE__))
    end
    let(:fpc_logical) do
      File.expand_path('../../files/backups/fpc_logical', File.dirname(__FILE__))
    end
    let(:no_configs) do
      File.expand_path('../../files/backups/no_configs', File.dirname(__FILE__))
    end

    it 'Validates katello standard backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      kat_stand_backup = subject.new(katello_standard)
      assert kat_stand_backup.katello_standard_backup?
      assert !kat_stand_backup.katello_online_backup?
      assert !kat_stand_backup.katello_logical_backup?
      assert !kat_stand_backup.foreman_standard_backup?
      assert !kat_stand_backup.foreman_online_backup?
      assert !kat_stand_backup.foreman_logical_backup?
      assert !kat_stand_backup.fpc_standard_backup?
      assert !kat_stand_backup.fpc_online_backup?
      assert !kat_stand_backup.fpc_logical_backup?
    end

    it 'Validates katello online backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      kat_online_backup = subject.new(katello_online)
      assert !kat_online_backup.katello_standard_backup?
      assert kat_online_backup.katello_online_backup?
      assert !kat_online_backup.katello_logical_backup?
      assert !kat_online_backup.foreman_standard_backup?
      assert !kat_online_backup.foreman_online_backup?
      assert !kat_online_backup.foreman_logical_backup?
      assert !kat_online_backup.fpc_standard_backup?
      assert !kat_online_backup.fpc_online_backup?
      assert !kat_online_backup.fpc_logical_backup?
    end

    it 'Validates katello logical backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      kat_logical_backup = subject.new(katello_logical)
      assert !kat_logical_backup.katello_standard_backup?
      assert !kat_logical_backup.katello_online_backup?
      assert kat_logical_backup.katello_logical_backup?
      assert !kat_logical_backup.foreman_standard_backup?
      assert !kat_logical_backup.foreman_online_backup?
      assert !kat_logical_backup.foreman_logical_backup?
      assert !kat_logical_backup.fpc_standard_backup?
      assert !kat_logical_backup.fpc_online_backup?
      assert !kat_logical_backup.fpc_logical_backup?
    end

    it 'Validates foreman standard backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      foreman_standard_backup = subject.new(foreman_standard)
      assert !foreman_standard_backup.katello_standard_backup?
      assert !foreman_standard_backup.katello_online_backup?
      assert !foreman_standard_backup.katello_logical_backup?
      assert foreman_standard_backup.foreman_standard_backup?
      assert !foreman_standard_backup.foreman_online_backup?
      assert !foreman_standard_backup.foreman_logical_backup?
      assert !foreman_standard_backup.fpc_standard_backup?
      assert !foreman_standard_backup.fpc_online_backup?
      assert !foreman_standard_backup.fpc_logical_backup?
    end

    it 'Validates foreman online backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      foreman_online_backup = subject.new(foreman_online)
      assert !foreman_online_backup.katello_standard_backup?
      assert !foreman_online_backup.katello_online_backup?
      assert !foreman_online_backup.katello_logical_backup?
      assert !foreman_online_backup.foreman_standard_backup?
      assert foreman_online_backup.foreman_online_backup?
      assert !foreman_online_backup.foreman_logical_backup?
      assert !foreman_online_backup.fpc_standard_backup?
      assert !foreman_online_backup.fpc_online_backup?
      assert !foreman_online_backup.fpc_logical_backup?
    end

    it 'Validates foreman logical backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      foreman_logical_backup = subject.new(foreman_logical)
      assert !foreman_logical_backup.katello_standard_backup?
      assert !foreman_logical_backup.katello_online_backup?
      assert !foreman_logical_backup.katello_logical_backup?
      assert !foreman_logical_backup.foreman_standard_backup?
      assert !foreman_logical_backup.foreman_online_backup?
      assert foreman_logical_backup.foreman_logical_backup?
      assert !foreman_logical_backup.fpc_standard_backup?
      assert !foreman_logical_backup.fpc_online_backup?
      assert !foreman_logical_backup.fpc_logical_backup?
    end

    it 'Validates fpc standard backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      fpc_standard_backup = subject.new(fpc_standard)
      assert !fpc_standard_backup.katello_standard_backup?
      assert !fpc_standard_backup.katello_online_backup?
      assert !fpc_standard_backup.katello_logical_backup?
      assert !fpc_standard_backup.foreman_standard_backup?
      assert !fpc_standard_backup.foreman_online_backup?
      assert !fpc_standard_backup.foreman_logical_backup?
      assert fpc_standard_backup.fpc_standard_backup?
      assert !fpc_standard_backup.fpc_online_backup?
      assert !fpc_standard_backup.fpc_logical_backup?
    end

    it 'Validates fpc online backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      fpc_online_backup = subject.new(fpc_online)
      assert !fpc_online_backup.katello_standard_backup?
      assert !fpc_online_backup.katello_online_backup?
      assert !fpc_online_backup.katello_logical_backup?
      assert !fpc_online_backup.foreman_standard_backup?
      assert !fpc_online_backup.foreman_online_backup?
      assert !fpc_online_backup.foreman_logical_backup?
      assert !fpc_online_backup.fpc_standard_backup?
      assert fpc_online_backup.fpc_online_backup?
      assert !fpc_online_backup.fpc_logical_backup?
    end

    it 'Validates fpc logical backup' do
      ForemanMaintain.detector.stubs(:feature).with(:pulpcore).returns(true)
      fpc_logical_backup = subject.new(fpc_logical)
      assert !fpc_logical_backup.katello_standard_backup?
      assert !fpc_logical_backup.katello_online_backup?
      assert !fpc_logical_backup.katello_logical_backup?
      assert !fpc_logical_backup.foreman_standard_backup?
      assert !fpc_logical_backup.foreman_online_backup?
      assert !fpc_logical_backup.foreman_logical_backup?
      assert !fpc_logical_backup.fpc_standard_backup?
      assert !fpc_logical_backup.fpc_online_backup?
      assert fpc_logical_backup.fpc_logical_backup?
    end

    it 'does not validate backup without config_files.tar.gz' do
      no_configs_backup = subject.new(no_configs)
      assert !no_configs_backup.valid_backup?
    end

    it 'recognizes incremental backup' do
      incremental_backup = subject.new(katello_standard_incremental)
      assert incremental_backup.incremental?
    end

    it 'Validates hostname from the backup' do
      kat_stand_backup = subject.new(katello_standard)
      kat_stand_backup.stubs(:hostname).returns('sat-6.example.com')
      assert kat_stand_backup.validate_hostname?
    end
  end
end
