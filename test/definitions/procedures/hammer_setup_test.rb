require 'test_helper'

describe Procedures::HammerSetup do
  include DefinitionsTestHelper

  subject do
    Procedures::HammerSetup.new
  end

  let :hammer_instance do
    ForemanMaintain::Utils::Hammer.instance
  end

  let :default_config_file do
    File.join(TEST_DIR, 'config', 'foreman-maintain-hammer-default.yml')
  end

  def setup
    super
    hammer_instance.stubs(:default_config_file => default_config_file)
    [hammer_instance.config_file, default_config_file].each do |file|
      File.delete(file) if File.exist?(file)
    end
  end

  def store_config_file(path)
    File.open(path, 'w') do |f|
      f.puts YAML.dump(:foreman => { :username => 'admin', :password => 'changeme' })
    end
  end

  context 'the hammer is already configured' do
    specify 'necessary? returns false' do
      hammer_instance.stubs(:run_command => true)
      store_config_file(hammer_instance.config_file)
      refute subject.necessary?, 'hammer setup should not be necessary'
    end
  end

  context 'there is a default configuration with valid credentials' do
    it 'copies over the hammer configuration and uses it' do
      store_config_file(default_config_file)
      hammer_instance.stubs(:run_command => true)
      File.open(hammer_instance.config_file, 'w') do |f|
        f.puts YAML.dump(:username => 'admin', :password => 'changeme')
      end
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
      assert_stdout <<-OUT.strip_heredoc
        Using defaults from #{default_config_file}
        New settings saved into #{hammer_instance.config_file}
      OUT
    end
  end

  context 'correct credentials are entered' do
    it 'stores the credentials into the configuration' do
      log_reporter.input << '' << 'password'
      hammer_instance.stubs(:run_command => true)
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
      assert_stdout <<-OUT.strip_heredoc
        Hammer username [admin]:
        Hammer password:
        New settings saved into #{hammer_instance.config_file}
      OUT
      assert_equal({ :foreman => { :username => 'admin', :password => 'password' } },
                   YAML.load_file(hammer_instance.config_file),
                   'Credentials should be saved to the file')
    end
  end

  context 'incorrect credentials are entered' do
    it 'asks again for the credentials' do
      log_reporter.input << 'john' << 'password' << 'John' << 'Password'
      # simulate first command failing while the second succeeding
      hammer_instance.stubs(:execute).returns('Invalid username or password', '')
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
      assert_stdout <<-OUT.strip_heredoc
        Hammer username [admin]:
        Hammer password:
        Invalid credentials
        Hammer username [admin]:
        Hammer password:
        New settings saved into #{hammer_instance.config_file}
      OUT
      assert_equal({ :foreman => { :username => 'John', :password => 'Password' } },
                   YAML.load_file(hammer_instance.config_file),
                   'Credentials should be saved to the file')
    end
  end
end
