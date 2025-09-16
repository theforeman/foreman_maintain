require 'test_helper'

describe Procedures::Pulpcore::RpmDatarepair do
  include DefinitionsTestHelper

  subject { Procedures::Pulpcore::RpmDatarepair.new }

  it 'runs pulpcore-manager rpm-datarepair 4073' do
    assume_feature_present(:pulpcore)
    assume_feature_present(:pulpcore_database, :services => [])
    assume_feature_present(:service)

    subject.expects(:execute!).with(
      'PULP_SETTINGS=/etc/pulp/settings.py runuser -u pulp -- ' \
      'pulpcore-manager rpm-datarepair 4073'
    ).once

    result = run_procedure(subject)
    assert result.success?
  end
end
