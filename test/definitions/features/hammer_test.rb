require 'test_helper'

describe Features::Hammer do
  include DefinitionsTestHelper

  subject { Features::Hammer.new }
  let(:data_dir) { File.join(File.dirname(__FILE__), '../../data') }
  let(:subject_ins) { Features::Hammer.any_instance }

  def stub_connection_check(*results)
    subject_ins.stubs(:_check_connection).returns(*results)
  end

  def stub_hostname(hostname = 'example.com')
    subject_ins.stubs(:hostname).returns(hostname)
  end

  it 'loads list of configs on the start' do
    hammer_config_dirs(["#{data_dir}/hammer/sample_user_config"])
    expected_config_files = [
      "#{data_dir}/hammer/sample_user_config/cli_config.yml",
      "#{data_dir}/hammer/sample_user_config/cli.modules.d/foreman.yml"
    ].map { |p| File.expand_path(p) }

    subject.config_files.must_equal(expected_config_files)
  end

  it 'loads and merges hammer configuration' do
    hammer_config_dirs([
                         "#{data_dir}/hammer/sample_user_config",
                         "#{data_dir}/hammer/sample_default_config"
                       ])
    subject.configuration[:log_level].must_equal('error')
    subject.configuration[:foreman][:username].must_equal('user')
    subject.configuration[:foreman][:password].must_equal('password')
    subject.configuration[:foreman][:host].must_equal('https://example.com/')
  end

  it 'can run commands' do
    stub_connection_check(true)
    subject_ins.expects(:execute).with(subject.command_base + ' ping')
    subject.run('ping')
  end

  describe 'command_base' do
    it 'adds custom config when present' do
      config = "#{data_dir}/hammer/sample_user_config/cli_config.yml"
      subject_ins.stubs(:custom_config_file).returns(config)
      expected_command = "RUBYOPT='-W0' LANG=en_US.utf-8 hammer -c \"#{config}\" --interactive=no"
      subject.command_base.must_equal(expected_command)
    end

    it 'adds custom config when present' do
      config = 'missing'
      subject_ins.stubs(:custom_config_file).returns(config)
      subject.command_base.must_equal("RUBYOPT='-W0' LANG=en_US.utf-8 hammer --interactive=no")
    end
  end

  describe 'setup_admin_access' do
    def expect_custom_config(config)
      Features::Hammer.any_instance.expects(:save_config).with(config)
    end

    before do
      assume_feature_present(:installer)
      mock_installer_package('foreman-installer')
      installer_config_dir("#{data_dir}/installer/simple_config")
    end

    it 'gets credentials from hammer configs' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/sample_admin_config",
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_hostname
      stub_connection_check(false, true)

      expect_custom_config(:foreman => { :username => 'admin' })
      subject.setup_admin_access.must_equal true
    end

    it 'replaces different host' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/different_host_config",
                           "#{data_dir}/hammer/sample_admin_config",
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_connection_check(false, true)

      expect_custom_config(:foreman => { :username => 'admin', :host => subject.server_uri })
      subject.setup_admin_access.must_equal true
    end

    it 'gets credentials from answer files when no password' do
      hammer_config_dirs(["#{data_dir}/hammer/sample_default_config"])
      stub_hostname
      stub_connection_check(false, true)

      expect_custom_config(:foreman => { :username => 'admin', :password => 'inspasswd' })
      subject.setup_admin_access.must_equal true
    end

    it 'gets credentials from answer files when invalid password' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/sample_admin_config",
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_hostname
      stub_connection_check(false, false, true)
      expect_custom_config(:foreman => { :username => 'admin' })
      expect_custom_config(:foreman => { :username => 'admin', :password => 'inspasswd' })
      subject.setup_admin_access.must_equal true
    end

    it 'makes sure we use admin account and ignore the non-admin password' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/sample_user_config",
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_hostname
      stub_connection_check(false, true)
      expect_custom_config(:foreman => { :username => 'admin', :password => 'inspasswd' })
      subject.setup_admin_access.must_equal true
    end

    it 'asks if the installer stored password is wrong' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_hostname
      stub_connection_check(false, false, true)
      log_reporter.input << 'manual'
      expect_custom_config(:foreman => { :username => 'admin', :password => 'inspasswd' })
      expect_custom_config(:foreman => { :username => 'admin', :password => 'manual' })
      subject.setup_admin_access.must_equal true
      log_reporter.output.must_equal "Hammer admin password:\n"
    end

    it 'fails when the interractive password is wrong' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_hostname
      stub_connection_check(false, false)
      log_reporter.input << 'manual'
      expect_custom_config(:foreman => { :username => 'admin', :password => 'inspasswd' })
      expect_custom_config(:foreman => { :username => 'admin', :password => 'manual' })
      proc { subject.setup_admin_access }.must_raise(ForemanMaintain::HammerConfigurationError)
      subject.ready?.must_equal false
    end

    it 'uses stored values from last time if still valid' do
      hammer_config_dirs([])
      stub_connection_check(true)
      subject_ins.expects(:save_config).never
      subject.setup_admin_access.must_equal true
    end

    it 'ignores stored values from last time if invalid' do
      hammer_config_dirs([
                           "#{data_dir}/hammer/sample_admin_config",
                           "#{data_dir}/hammer/sample_default_config"
                         ])
      stub_hostname
      stub_connection_check(false, true)
      expect_custom_config(:foreman => { :username => 'admin' })
      subject.setup_admin_access.must_equal true
    end
  end
end
