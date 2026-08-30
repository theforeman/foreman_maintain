require 'test_helper'

describe Features::ForemanDatabase do
  include DefinitionsTestHelper

  subject { Features::ForemanDatabase.new }

  describe '.configuration' do
    it 'returns hash with DB config and connection_string' do
      database_yml_content = {
        'production' => {
          'adapter' => 'postgresql',
          'host' => 'localhost',
          'port' => 5432,
          'database' => 'foreman',
          'username' => 'foreman',
          'password' => 'password',
        },
      }

      File.expects(:exist?).with('/etc/foreman/database.yml').returns(true)
      File.expects(:read).with('/etc/foreman/database.yml').returns('mocked_yaml_content')
      YAML.expects(:load).with('mocked_yaml_content').returns(database_yml_content)

      expected = {
        'adapter' => 'postgresql',
        'host' => 'localhost',
        'port' => 5432,
        'database' => 'foreman',
        'username' => 'foreman',
        'password' => 'password',
        'connection_string' => 'postgres:///foreman',
      }
      assert_equal expected, subject.configuration
    end
  end
end
