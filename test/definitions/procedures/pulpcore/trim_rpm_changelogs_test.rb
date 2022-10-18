require 'test_helper'

describe Procedures::Pulpcore::TrimRpmChangelogs do
  include DefinitionsTestHelper

  subject do
    Procedures::Pulpcore::TrimRpmChangelogs.new
  end

  before do
    assume_feature_present(:pulpcore, :services => [])
    assume_feature_present(:pulpcore_database, :configuration => {})
  end

  it 'trims RPM changelogs' do
    trim_command = 'sudo PULP_SETTINGS=/etc/pulp/settings.py '\
      'DJANGO_SETTINGS_MODULE=pulpcore.app.settings '\
      'pulpcore-manager rpm-trim-changelogs'

    subject.stubs(:'execute!').with(trim_command).returns(0)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
