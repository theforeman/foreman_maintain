require 'test_helper'

describe Procedures::Restore::ReindexDatabases do
  include DefinitionsTestHelper

  subject do
    Procedures::Restore::ReindexDatabases.new
  end

  before do
    assume_feature_present(:instance, :postgresql_local? => true)
    assume_feature_present(:foreman_database, :configuration => {})
    Features::Service.any_instance.expects(:handle_services)
  end

  it 'reindexes all DBs if DB is local' do
    reindex_command = 'runuser - postgres -c "reindexdb -a"'

    subject.stubs(:'execute!').with(reindex_command).returns(0)
    subject.stubs(:check_min_version).returns(false)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end

  it 'reindexes all DBs if DB is local and pulp-ansible is present' do
    reindex_command = 'runuser - postgres -c "reindexdb -a"'
    collate_command = 'runuser -c \'echo "ALTER COLLATION pulp_ansible_semver REFRESH VERSION;"'\
                       '| psql pulpcore\' postgres'

    subject.stubs(:'execute!').with(reindex_command).returns(0)
    subject.stubs(:check_min_version).with('python3.11-pulp-ansible', '0.20.0').returns(true)
    subject.stubs(:'execute!').with(collate_command).returns(0)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
