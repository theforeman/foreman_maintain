require 'test_helper'

describe Features::Mongo do
  include DefinitionsTestHelper

  subject { Features::Mongo.new }
  let(:data_dir) { File.join(File.dirname(__FILE__), '../../data') }
  let(:subject_ins) { Features::Mongo.any_instance }

  def stub_config_file(cfg)
    subject_ins.stubs(:config_file).returns(cfg)
  end

  def stub_hostname(hostname = 'example.com')
    subject_ins.stubs(:hostname).returns(hostname)
  end

  it 'loads configuration on the start' do
    stub_config_file("#{data_dir}/mongo/default_server.conf")
    expected_config = {
      'name' => 'pulp_database',
      'seeds' => 'mymongo:27019',
      'ssl' => false,
      'unsafe_autoretry' => false,
      'host' => 'mymongo',
      'port' => '27019',
    }
    subject.configuration.must_equal expected_config
  end

  describe '#local_db?' do
    it 'recognizes if db is remote' do
      stub_hostname('server')
      stub_config_file("#{data_dir}/mongo/default_server.conf")
      subject.local?.must_equal false
    end

    it 'recognizes if the db is local' do
      stub_hostname('mymongo')
      stub_config_file("#{data_dir}/mongo/default_server.conf")
      subject.local?.must_equal true
    end
  end

  describe '#base_command' do
    it 'produce command with right parameters' do
      stub_config_file("#{data_dir}/mongo/default_server.conf")
      subject.base_command('mongo').must_equal 'mongo --host mymongo --port 27019 '
    end

    it 'produce command with right parameters for SSL without verification' do
      stub_config_file("#{data_dir}/mongo/self_signed_certs_server.conf")
      cmd = 'mongo --host mymongo --port 27019 --ssl --sslAllowInvalidCertificates' \
            ' --sslCAFile /etc/pki/tls/certs/test_ca.pem '
      subject.base_command('mongo').must_equal cmd
    end
  end
end
