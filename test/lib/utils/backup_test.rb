require 'test_helper'
require File.expand_path('../../../lib/foreman_maintain/utils/backup.rb',
  File.dirname(__FILE__))

module ForemanMaintain
  describe Utils::Backup do
    subject { Utils::Backup }

    let(:katello_standard) do
      file_path = '../../files/backups/katello_standard_pulpcore_database'
      File.expand_path(file_path, File.dirname(__FILE__))
    end
    let(:katello_standard_incremental) do
      File.expand_path('../../files/backups/katello_standard_incremental', File.dirname(__FILE__))
    end
    let(:katello_online) do
      file_path = '../../files/backups/katello_online_pulpcore_database'
      File.expand_path(file_path, File.dirname(__FILE__))
    end
    let(:katello_logical) do
      file_path = '../../files/backups/katello_logical_pulpcore_database'
      File.expand_path(file_path, File.dirname(__FILE__))
    end
    let(:katello_hybrid_db_backup) do
      file_path = '../../files/backups/katello_hybrid_db_backup/'
      File.expand_path(file_path, File.dirname(__FILE__))
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
      File.expand_path('../../files/backups/fpc_standard_pulpcore_database', File.dirname(__FILE__))
    end
    let(:fpc_online) do
      File.expand_path('../../files/backups/fpc_online_pulpcore_database', File.dirname(__FILE__))
    end
    let(:fpc_logical) do
      File.expand_path('../../files/backups/fpc_logical_pulpcore_database', File.dirname(__FILE__))
    end
    let(:fpc_hybrid) do
      File.expand_path('../../files/backups/fpc_hybrid_database_backup', File.dirname(__FILE__))
    end
    let(:no_configs) do
      File.expand_path('../../files/backups/no_configs', File.dirname(__FILE__))
    end

    def assume_feature_present(label)
      ForemanMaintain.detector.stubs(:feature).with(label).returns(true)
    end

    def assume_feature_absent(label)
      ForemanMaintain.detector.stubs(:feature).with(label).returns(false)
    end

    def feature_with_local_method(label, return_value)
      fake_feature = MiniTest::Mock.new
      ret_hash = { 'host' => 'abc.example.com' }
      fake_feature.expect(:configuration, ret_hash)
      fake_feature.expect(:local?, return_value)
      ForemanMaintain.detector.stubs(:feature).with(label).returns(fake_feature)
    end

    it 'Validates katello standard backup' do
      assume_feature_present(:pulpcore_database)
      kat_stand_backup = subject.new(katello_standard)
      assert kat_stand_backup.katello_standard_backup?
      refute kat_stand_backup.katello_online_backup?
      refute kat_stand_backup.katello_logical_backup?
      refute kat_stand_backup.foreman_online_backup?
      refute kat_stand_backup.foreman_logical_backup?
      refute kat_stand_backup.fpc_online_backup?
      refute kat_stand_backup.fpc_logical_backup?
    end

    it 'Validates katello online backup' do
      assume_feature_present(:pulpcore_database)
      kat_online_backup = subject.new(katello_online)
      refute kat_online_backup.katello_standard_backup?
      assert kat_online_backup.katello_online_backup?
      refute kat_online_backup.katello_logical_backup?
      refute kat_online_backup.foreman_standard_backup?
      refute kat_online_backup.foreman_online_backup?
      refute kat_online_backup.foreman_logical_backup?
      refute kat_online_backup.fpc_standard_backup?
      refute kat_online_backup.fpc_online_backup?
      refute kat_online_backup.fpc_logical_backup?
    end

    it 'Validates katello logical backup' do
      assume_feature_present(:pulpcore_database)
      kat_logical_backup = subject.new(katello_logical)
      refute kat_logical_backup.katello_standard_backup?
      refute kat_logical_backup.katello_online_backup?
      assert kat_logical_backup.katello_logical_backup?
      refute kat_logical_backup.foreman_standard_backup?
      refute kat_logical_backup.foreman_online_backup?
      refute kat_logical_backup.foreman_logical_backup?
      refute kat_logical_backup.fpc_standard_backup?
      refute kat_logical_backup.fpc_online_backup?
      refute kat_logical_backup.fpc_logical_backup?
    end

    it 'Validates katello hybrid db backup' do
      assume_feature_present(:pulpcore_database)
      assume_feature_present(:candlepin_database)
      assume_feature_present(:foreman_database)
      feature_with_local_method(:pulpcore_database, true)
      feature_with_local_method(:candlepin_database, false)
      feature_with_local_method(:foreman_database, false)
      kat_hybrid_db_backup = subject.new(katello_hybrid_db_backup)
      refute kat_hybrid_db_backup.katello_standard_backup?
      refute kat_hybrid_db_backup.katello_online_backup?
      refute kat_hybrid_db_backup.katello_logical_backup?
      assert kat_hybrid_db_backup.katello_hybrid_db_backup?
      refute kat_hybrid_db_backup.foreman_standard_backup?
      refute kat_hybrid_db_backup.foreman_online_backup?
      refute kat_hybrid_db_backup.foreman_logical_backup?
      refute kat_hybrid_db_backup.fpc_standard_backup?
      refute kat_hybrid_db_backup.fpc_online_backup?
      refute kat_hybrid_db_backup.fpc_logical_backup?
    end

    it 'Validates foreman standard backup' do
      foreman_standard_backup = subject.new(foreman_standard)
      assert foreman_standard_backup.katello_standard_backup?
      refute foreman_standard_backup.katello_online_backup?
      refute foreman_standard_backup.katello_logical_backup?
      assert foreman_standard_backup.foreman_standard_backup?
      refute foreman_standard_backup.foreman_online_backup?
      refute foreman_standard_backup.foreman_logical_backup?
      assert foreman_standard_backup.fpc_standard_backup?
      refute foreman_standard_backup.fpc_online_backup?
      refute foreman_standard_backup.fpc_logical_backup?
    end

    it 'Validates foreman online backup' do
      assume_feature_absent(:pulpcore_database)
      foreman_online_backup = subject.new(foreman_online)
      refute foreman_online_backup.katello_standard_backup?
      refute foreman_online_backup.katello_online_backup?
      refute foreman_online_backup.katello_logical_backup?
      refute foreman_online_backup.foreman_standard_backup?
      assert foreman_online_backup.foreman_online_backup?
      refute foreman_online_backup.foreman_logical_backup?
      refute foreman_online_backup.fpc_standard_backup?
      refute foreman_online_backup.fpc_online_backup?
      refute foreman_online_backup.fpc_logical_backup?
    end

    it 'Validates foreman logical backup' do
      assume_feature_absent(:pulpcore_database)
      foreman_logical_backup = subject.new(foreman_logical)
      refute foreman_logical_backup.katello_standard_backup?
      refute foreman_logical_backup.katello_online_backup?
      refute foreman_logical_backup.katello_logical_backup?
      refute foreman_logical_backup.foreman_standard_backup?
      refute foreman_logical_backup.foreman_online_backup?
      assert foreman_logical_backup.foreman_logical_backup?
      refute foreman_logical_backup.fpc_standard_backup?
      refute foreman_logical_backup.fpc_online_backup?
      refute foreman_logical_backup.fpc_logical_backup?
    end

    it 'Validates fpc standard backup' do
      assume_feature_present(:pulpcore_database)
      fpc_standard_backup = subject.new(fpc_standard)
      refute fpc_standard_backup.katello_online_backup?
      refute fpc_standard_backup.katello_logical_backup?
      refute fpc_standard_backup.foreman_online_backup?
      refute fpc_standard_backup.foreman_logical_backup?
      assert fpc_standard_backup.fpc_standard_backup?
      refute fpc_standard_backup.fpc_online_backup?
      refute fpc_standard_backup.fpc_logical_backup?
    end

    it 'Validates fpc online backup' do
      assume_feature_present(:pulpcore_database)
      fpc_online_backup = subject.new(fpc_online)
      refute fpc_online_backup.katello_standard_backup?
      refute fpc_online_backup.katello_online_backup?
      refute fpc_online_backup.katello_logical_backup?
      refute fpc_online_backup.foreman_standard_backup?
      refute fpc_online_backup.foreman_online_backup?
      refute fpc_online_backup.foreman_logical_backup?
      refute fpc_online_backup.fpc_standard_backup?
      assert fpc_online_backup.fpc_online_backup?
      refute fpc_online_backup.fpc_logical_backup?
    end

    it 'Validates fpc logical backup' do
      assume_feature_present(:pulpcore_database)
      fpc_logical_backup = subject.new(fpc_logical)
      refute fpc_logical_backup.katello_standard_backup?
      refute fpc_logical_backup.katello_online_backup?
      refute fpc_logical_backup.katello_logical_backup?
      refute fpc_logical_backup.foreman_standard_backup?
      refute fpc_logical_backup.foreman_online_backup?
      refute fpc_logical_backup.foreman_logical_backup?
      refute fpc_logical_backup.fpc_standard_backup?
      refute fpc_logical_backup.fpc_online_backup?
      assert fpc_logical_backup.fpc_logical_backup?
    end

    it 'Validates fpc hybrid db backup' do
      feature_with_local_method(:pulpcore_database, true)
      fpc_hybrid_db_backup = subject.new(fpc_hybrid)
      assert fpc_hybrid_db_backup.katello_standard_backup?
      refute fpc_hybrid_db_backup.katello_online_backup?
      refute fpc_hybrid_db_backup.katello_logical_backup?
      assert fpc_hybrid_db_backup.foreman_standard_backup?
      refute fpc_hybrid_db_backup.foreman_online_backup?
      refute fpc_hybrid_db_backup.foreman_logical_backup?
      assert fpc_hybrid_db_backup.fpc_standard_backup?
      refute fpc_hybrid_db_backup.fpc_online_backup?
      refute fpc_hybrid_db_backup.fpc_logical_backup?
      assert fpc_hybrid_db_backup.fpc_hybrid_db_backup?
    end

    it 'does not validate backup without config_files.tar.gz' do
      no_configs_backup = subject.new(no_configs)
      refute no_configs_backup.valid_backup?
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

    it 'accepts backup without proxy config in the metadata' do
      backup = subject.new(katello_standard)
      Dir.stubs(:entries).returns(%w[. .. lo eth0])
      assert_empty backup.validate_interfaces
    end

    it 'accepts backup with proxy config and disabled DHCP/DNS in the metadata' do
      backup = subject.new(katello_standard)
      Dir.stubs(:entries).returns(%w[. .. lo eth0])
      backup.stubs(:metadata).returns('proxy_config' =>
                                      { 'dhcp' => false,
                                        'dhcp_interface' => 'eth0',
                                        'dns' => false,
                                        'dns_interface' => 'eth0' })
      assert_empty backup.validate_interfaces
    end

    it 'accepts backup when DHCP/DNS configured interfaces are found on system' do
      backup = subject.new(katello_standard)
      Dir.stubs(:entries).returns(%w[. .. lo eth0])
      backup.stubs(:metadata).returns('proxy_config' =>
                                      { 'dhcp' => true,
                                        'dhcp_interface' => 'eth0',
                                        'dns' => true,
                                        'dns_interface' => 'eth0' })
      assert_empty backup.validate_interfaces
    end

    it 'rejects backup when DHCP/DNS configured interfaces are not found on system' do
      backup = subject.new(katello_standard)
      Dir.stubs(:entries).returns(%w[. .. lo eth1])
      backup.stubs(:metadata).returns('proxy_config' =>
                                      { 'dhcp' => true,
                                        'dhcp_interface' => 'eth0',
                                        'dns' => true,
                                        'dns_interface' => 'eth0' })
      refute_empty backup.validate_interfaces
      assert backup.validate_interfaces['dns']['configured'] = 'eth0'
      assert backup.validate_interfaces['dhcp']['configured'] = 'eth0'
    end

    it 'detects backup with puppetserver installed' do
      backup = subject.new(katello_standard)
      backup.stubs(:metadata).returns('rpms' => ['puppetserver-7.4.2-1.el8.noarch'])
      assert backup.with_puppetserver?
    end

    it 'detects backup without puppetserver installed' do
      backup = subject.new(katello_standard)
      backup.stubs(:metadata).returns('rpms' => ['ansible-core-2.14.2-4.el8_8.x86_64'])
      refute backup.with_puppetserver?
    end

    it 'detects backup with qpidd installed' do
      backup = subject.new(katello_standard)
      backup.stubs(:metadata).returns('rpms' => ['qpid-cpp-server-1.36.0-32.el7_9amq.x86_64'])
      assert backup.with_qpidd?
    end

    it 'detects backup without qpidd installed' do
      backup = subject.new(katello_standard)
      backup.stubs(:metadata).returns('rpms' => ['qpid-cpp-client-1.36.0-32.el7_9amq.x86_64'])
      refute backup.with_qpidd?
    end
  end
end
