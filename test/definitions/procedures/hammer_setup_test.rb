require 'test_helper'

describe Procedures::HammerSetup do
  include DefinitionsTestHelper

  subject do
    Procedures::HammerSetup.new
  end

  let :hammer_ins do
    Features::Hammer.any_instance
  end

  let :default_config_file do
    File.join(TEST_DIR, 'config', 'foreman-maintain-hammer-default.yml')
  end

  def store_config_file(path)
    File.open(path, 'w') do |f|
      f.puts YAML.dump(:foreman => { :username => 'admin', :password => 'changeme' })
    end
  end

  before do
    assume_feature_present(:hammer)
  end

  context 'the hammer is already configured' do
    specify 'necessary? returns false' do
      hammer_ins.stubs(:_check_connection).returns(true)
      refute subject.necessary?, 'hammer setup should not be necessary'
    end
  end

  context 'there is a default configuration with valid credentials' do
    it 'uses the default config and sets the feature' do
      httpd_service = assume_service_running('httpd')
      assume_feature_present(:foreman_server, :services => [httpd_service])
      hammer_ins.stubs(:_check_connection).returns(true)
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
      feature(:hammer).ready?.must_equal true
    end
  end

  context 'there is a configuration with invalid credentials' do
    it 'calls setup_admin_access and sets the feature' do
      httpd_service = assume_service_running('httpd')
      assume_feature_present(:foreman_server, :services => [httpd_service])
      hammer_ins.stubs(:_check_connection).returns(false)
      hammer_ins.expects(:setup_admin_access).returns(true)
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
    end

    it 'skips setup_admin_access if httpd is down' do
      httpd_service = assume_service_stopped('httpd')
      Features::Instance.any_instance.stubs(:product_name => 'Foreman')
      assume_feature_present(:foreman_server, :services => [httpd_service])
      hammer_ins.stubs(:_check_connection).returns(false)
      hammer_ins.expects(:setup_admin_access).never
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
      assert result.status, :skipped
    end
  end
end
