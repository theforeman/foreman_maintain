require 'test_helper'

describe Procedures::Pulpcore::ContainerRepairMediaType do
  include DefinitionsTestHelper

  subject do
    Procedures::Pulpcore::ContainerRepairMediaType.new
  end

  before do
    assume_feature_present(:pulpcore, :services => [])
    assume_feature_present(:pulpcore_database, :configuration => {})
  end

  it 'repairs container media type' do
    repair_command = 'PULP_SETTINGS=/etc/pulp/settings.py '\
                     'DJANGO_SETTINGS_MODULE=pulpcore.app.settings '\
                     'pulpcore-manager container-repair-media-type'

    subject.stubs(:'execute!').with(repair_command).returns(0)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
