require 'test_helper'
require 'minitest/stub_const'

describe Features::CandlepinDatabase do
  include DefinitionsTestHelper
  subject { Features::CandlepinDatabase.new }
  let(:subject_ins) { Features::CandlepinDatabase.any_instance }

  let(:cp_config_dir) do
    File.expand_path('../../support', __dir__)
  end

  def stub_with_ssl_config(&block)
    Features::CandlepinDatabase.stub_const(:CANDLEPIN_DB_CONFIG,
      cp_config_dir + '/candlepin_with_ssl.conf', &block)
  end

  def stub_without_ssl_config(&block)
    Features::CandlepinDatabase.stub_const(:CANDLEPIN_DB_CONFIG,
      cp_config_dir + '/candlepin_without_ssl.conf', &block)
  end

  describe '.configuration' do
    it 'The url includes ssl attributes when ssl is enabled' do
      stub_with_ssl_config do
        url = subject.configuration['url']
        assert_includes url, 'ssl=true'
        assert_includes url, 'sslrootcert=/usr/share/foreman/root.crt'
      end
    end

    it 'The url does not include ssl attributes when ssl is disabled' do
      stub_without_ssl_config do
        url = subject.configuration['url']
        refute_includes url, 'ssl=true'
        refute_includes url, 'sslrootcert=/usr/share/foreman/root.crt'
      end
    end

    it 'Sets connection_string for local database backups with SSL' do
      stub_with_ssl_config do
        config = subject.configuration
        assert_equal 'candlepin1db', config['database']
        assert_equal 'postgres:///candlepin1db', config['connection_string']
      end
    end

    it 'Sets connection_string for local database backups without SSL' do
      stub_without_ssl_config do
        config = subject.configuration
        assert_equal 'candlepin', config['database']
        assert_equal 'postgres:///candlepin', config['connection_string']
      end
    end
  end
end
