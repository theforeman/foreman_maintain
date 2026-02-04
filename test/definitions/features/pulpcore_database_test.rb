require 'test_helper'

describe Features::PulpcoreDatabase do
  include DefinitionsTestHelper

  subject { Features::PulpcoreDatabase.new }

  describe '.configuration' do
    it 'returns hash with DB config' do
      expected_command = <<~CMD.strip
        PULP_SETTINGS=/etc/pulp/settings.py runuser -u pulp -- pulpcore-manager shell --command 'from django.conf import settings; import json; print(json.dumps(settings.DATABASES["default"]))'
      CMD
      manager_return = <<~JSON
        {"ENGINE": "django.db.backends.postgresql", "NAME": "pulpcore", "USER": "pulp", "PASSWORD": "password", "HOST": "remotedb", "PORT": "5432"}
      JSON
      subject.expects(:execute!).with(expected_command, merge_stderr: false).returns(manager_return)
      expected = { "adapter" => "postgresql", "host" => "remotedb", "port" => "5432",
                   "database" => "pulpcore", "username" => "pulp", "password" => "password",
                   "connection_string" => "postgres:///pulpcore" }
      assert_equal expected, subject.configuration
    end
  end
end
