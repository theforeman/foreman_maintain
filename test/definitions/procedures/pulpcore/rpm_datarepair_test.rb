require 'test_helper'

describe Procedures::Pulpcore::RpmDatarepair do
  include DefinitionsTestHelper

  subject { Procedures::Pulpcore::RpmDatarepair.new }

  it 'runs rpm-datarepair 4007 when handler exists' do
    assume_feature_present(:pulpcore)
    assume_feature_present(:pulpcore_database, :services => [])
    assume_feature_present(:service)

    # Mock successful execution of 4007
    subject.expects(:execute_with_status).with(
      'PULP_SETTINGS=/etc/pulp/settings.py runuser -u pulp -- ' \
      'pulpcore-manager rpm-datarepair 4007'
    ).returns([0, ''])

    result = run_procedure(subject)
    assert result.success?
  end

  it 'gracefully skips rpm-datarepair 4007 if handler does not exist' do
    assume_feature_present(:pulpcore)
    assume_feature_present(:pulpcore_database, :services => [])
    assume_feature_present(:service)

    # Mock 4007 handler not existing
    subject.expects(:execute_with_status).with(
      'PULP_SETTINGS=/etc/pulp/settings.py runuser -u pulp -- ' \
      'pulpcore-manager rpm-datarepair 4007'
    ).returns([2, "CommandError: Unknown issue: '4007'"])

    result = run_procedure(subject)
    assert result.success?
  end
end
