require 'test_helper'
require 'minitest/stub_const'

describe Features::CandlepinDatabase do
  include DefinitionsTestHelper
  subject { Features::CandlepinDatabase.new }
  let(:subject_ins) { Features::CandlepinDatabase.any_instance }

  let(:cp_config_dir) do
    File.expand_path('../../../support/', __FILE__)
  end

  def stub_with_ssl_config
    Features::CandlepinDatabase.stub_const(:CANDLEPIN_DB_CONFIG,
                                           cp_config_dir + '/candlepin_with_ssl.conf') do
      yield
    end
  end

  def stub_without_ssl_config
    Features::CandlepinDatabase.stub_const(:CANDLEPIN_DB_CONFIG,
                                           cp_config_dir + '/candlepin_without_ssl.conf') do
      yield
    end
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
  end
end
