require 'test_helper'
require File.expand_path('../../../lib/foreman_maintain/utils/backup.rb',
  File.dirname(__FILE__))

module ForemanMaintain
  describe Utils::Backup do
    subject { Utils::Backup }

    let(:katello_online) do
      file_path = '../../files/backups/katello_online_pulpcore_database'
      File.expand_path(file_path, File.dirname(__FILE__))
    end
    let(:katello_online_incremental) do
      File.expand_path('../../files/backups/katello_online_incremental', File.dirname(__FILE__))
    end
    let(:foreman_online) do
      File.expand_path('../../files/backups/foreman_online', File.dirname(__FILE__))
    end
    let(:fpc_online) do
      File.expand_path('../../files/backups/fpc_online_pulpcore_database', File.dirname(__FILE__))
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

    it 'Validates katello online backup' do
      assume_feature_present(:pulpcore_database)
      kat_online_backup = subject.new(katello_online)
      assert kat_online_backup.katello_online_backup?
      refute kat_online_backup.foreman_online_backup?
      refute kat_online_backup.fpc_online_backup?
    end

    it 'Validates foreman online backup' do
      assume_feature_absent(:pulpcore_database)
      foreman_online_backup = subject.new(foreman_online)
      refute foreman_online_backup.katello_online_backup?
      assert foreman_online_backup.foreman_online_backup?
      refute foreman_online_backup.fpc_online_backup?
    end

    it 'Validates fpc online backup' do
      assume_feature_present(:pulpcore_database)
      assume_feature_present(:container_gateway_database)
      fpc_online_backup = subject.new(fpc_online)
      refute fpc_online_backup.katello_online_backup?
      refute fpc_online_backup.foreman_online_backup?
      assert fpc_online_backup.fpc_online_backup?
    end

    it 'does not validate backup without config_files.tar.gz' do
      no_configs_backup = subject.new(no_configs)
      refute no_configs_backup.valid_backup?
    end

    it 'recognizes incremental backup' do
      incremental_backup = subject.new(katello_online_incremental)
      assert incremental_backup.incremental?
    end

    it 'Validates hostname from the backup' do
      kat_stand_backup = subject.new(katello_online)
      kat_stand_backup.stubs(:hostname).returns('sat-6.example.com')
      assert kat_stand_backup.validate_hostname?
    end

    it 'accepts backup without proxy config in the metadata' do
      backup = subject.new(katello_online)
      Dir.stubs(:entries).returns(%w[. .. lo eth0])
      assert_empty backup.validate_interfaces
    end

    it 'accepts backup with proxy config and disabled DHCP/DNS in the metadata' do
      backup = subject.new(katello_online)
      Dir.stubs(:entries).returns(%w[. .. lo eth0])
      backup.stubs(:metadata).returns('proxy_config' =>
                                      { 'dhcp' => false,
                                        'dhcp_interface' => 'eth0',
                                        'dns' => false,
                                        'dns_interface' => 'eth0' })
      assert_empty backup.validate_interfaces
    end

    it 'accepts backup when DHCP/DNS configured interfaces are found on system' do
      backup = subject.new(katello_online)
      Dir.stubs(:entries).returns(%w[. .. lo eth0])
      backup.stubs(:metadata).returns('proxy_config' =>
                                      { 'dhcp' => true,
                                        'dhcp_interface' => 'eth0',
                                        'dns' => true,
                                        'dns_interface' => 'eth0' })
      assert_empty backup.validate_interfaces
    end

    it 'rejects backup when DHCP/DNS configured interfaces are not found on system' do
      backup = subject.new(katello_online)
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
      backup = subject.new(katello_online)
      backup.stubs(:metadata).returns('rpms' => ['puppetserver-7.4.2-1.el8.noarch'])
      assert backup.with_puppetserver?
    end

    it 'detects backup without puppetserver installed' do
      backup = subject.new(katello_online)
      backup.stubs(:metadata).returns('rpms' => ['ansible-core-2.14.2-4.el8_8.x86_64'])
      refute backup.with_puppetserver?
    end

    it 'detects backup from different OS' do
      backup = subject.new(katello_online)
      backup.stubs(:metadata).returns('os_version' => 'TestOS 1.2')
      backup.stubs(:os_name).returns('TestOS')
      backup.stubs(:os_version).returns('2.0')
      assert backup.different_source_os?
    end

    it 'detects backup from the same OS' do
      backup = subject.new(katello_online)
      backup.stubs(:metadata).returns('os_version' => 'TestOS 1.2')
      backup.stubs(:os_name).returns('TestOS')
      backup.stubs(:os_version).returns('1.2')
      refute backup.different_source_os?
    end
  end
end
