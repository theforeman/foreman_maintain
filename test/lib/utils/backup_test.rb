require 'test_helper'
require File.expand_path('../../../lib/foreman_maintain/utils/backup.rb',
                         File.dirname(__FILE__))

module ForemanMaintain
  describe Utils::Backup do
    subject { Utils::Backup }

    let(:katello_standard_pulp2) do
      File.expand_path('../../files/backups/katello_standard_pulp2', File.dirname(__FILE__))
    end
    let(:katello_standard_pulpcore) do
      File.expand_path('../../files/backups/katello_standard_pulpcore', File.dirname(__FILE__))
    end
    let(:katello_standard_incremental) do
      File.expand_path('../../files/backups/katello_standard_incremental', File.dirname(__FILE__))
    end
    let(:katello_online_pulp2) do
      File.expand_path('../../files/backups/katello_online_pulp2', File.dirname(__FILE__))
    end
    let(:katello_online_pulpcore) do
      File.expand_path('../../files/backups/katello_online_pulpcore', File.dirname(__FILE__))
    end
    let(:katello_logical_pulp2) do
      File.expand_path('../../files/backups/katello_logical_pulp2', File.dirname(__FILE__))
    end
    let(:katello_logical_pulpcore) do
      File.expand_path('../../files/backups/katello_logical_pulpcore', File.dirname(__FILE__))
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
    let(:fpc_standard_pulp2) do
      File.expand_path('../../files/backups/fpc_standard_pulp2', File.dirname(__FILE__))
    end
    let(:fpc_standard_pulpcore) do
      File.expand_path('../../files/backups/fpc_standard_pulpcore', File.dirname(__FILE__))
    end
    let(:fpc_online_pulp2) do
      File.expand_path('../../files/backups/fpc_online_pulp2', File.dirname(__FILE__))
    end
    let(:fpc_online_pulpcore) do
      File.expand_path('../../files/backups/fpc_online_pulpcore', File.dirname(__FILE__))
    end
    let(:fpc_logical_pulp2) do
      File.expand_path('../../files/backups/fpc_logical_pulp2', File.dirname(__FILE__))
    end
    let(:fpc_logical_pulpcore) do
      File.expand_path('../../files/backups/fpc_logical_pulpcore', File.dirname(__FILE__))
    end
    let(:no_configs) do
      File.expand_path('../../files/backups/no_configs', File.dirname(__FILE__))
    end

    def xor_pulp(feature)
      case feature
      when :pulp2
        assume_feature_present(:pulp2)
        assume_feature_absent(:pulpcore)
      when :pulpcore
        assume_feature_present(:pulpcore)
        assume_feature_absent(:pulp2)
      end
    end

    def assume_feature_present(label)
      ForemanMaintain.detector.stubs(:feature).with(label).returns(true)
    end

    def assume_feature_absent(label)
      ForemanMaintain.detector.stubs(:feature).with(label).returns(false)
    end

    it 'Validates katello standard backup' do
      [:pulp2, :pulpcore].each do |f|
        xor_pulp(f)
        kat_stand_backup = subject.new(send("katello_standard_#{f}"))
        assert kat_stand_backup.katello_standard_backup?
        assert !kat_stand_backup.katello_online_backup?
        assert !kat_stand_backup.katello_logical_backup?
        assert !kat_stand_backup.foreman_online_backup?
        assert !kat_stand_backup.foreman_logical_backup?
        assert !kat_stand_backup.fpc_online_backup?
        assert !kat_stand_backup.fpc_logical_backup?
        if f == :pulp2
          assert !kat_stand_backup.foreman_standard_backup?
          assert !kat_stand_backup.fpc_standard_backup?
        end
      end
    end

    it 'Validates katello online backup' do
      [:pulp2, :pulpcore].each do |f|
        xor_pulp(f)
        kat_online_backup = subject.new(send("katello_online_#{f}"))
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
    end

    it 'Validates katello logical backup' do
      [:pulp2, :pulpcore].each do |f|
        xor_pulp(f)
        kat_logical_backup = subject.new(send("katello_logical_#{f}"))
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
    end

    it 'Validates foreman standard backup' do
      assume_feature_absent(:pulp2)
      assume_feature_absent(:pulpcore)
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
      assume_feature_absent(:pulp2)
      assume_feature_absent(:pulpcore)
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
      assume_feature_absent(:pulp2)
      assume_feature_absent(:pulpcore)
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
      [:pulp2, :pulpcore].each do |f|
        xor_pulp(f)
        fpc_standard_backup = subject.new(send("fpc_standard_#{f}"))
        assert !fpc_standard_backup.katello_online_backup?
        assert !fpc_standard_backup.katello_logical_backup?
        assert !fpc_standard_backup.foreman_online_backup?
        assert !fpc_standard_backup.foreman_logical_backup?
        assert fpc_standard_backup.fpc_standard_backup?
        assert !fpc_standard_backup.fpc_online_backup?
        assert !fpc_standard_backup.fpc_logical_backup?
        if f == :pulp2
          assert !fpc_standard_backup.foreman_standard_backup?
        end
      end
    end

    it 'Validates fpc online backup' do
      [:pulp2, :pulpcore].each do |f|
        xor_pulp(f)
        fpc_online_backup = subject.new(send("fpc_online_#{f}"))
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
    end

    it 'Validates fpc logical backup' do
      [:pulp2, :pulpcore].each do |f|
        xor_pulp(f)
        fpc_logical_backup = subject.new(send("fpc_logical_#{f}"))
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
      kat_stand_backup = subject.new(katello_standard_pulp2)
      kat_stand_backup.stubs(:hostname).returns('sat-6.example.com')
      assert kat_stand_backup.validate_hostname?
    end
  end
end
