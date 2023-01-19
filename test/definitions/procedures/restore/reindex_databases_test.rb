require 'test_helper'

describe Procedures::Restore::ReindexDatabases do
  include DefinitionsTestHelper

  subject do
    Procedures::Restore::ReindexDatabases.new
  end

  before do
    assume_feature_present(:instance, :postgresql_local? => true)
    assume_feature_present(:foreman_database, :configuration => {})
  end

  it 'reindexes all DBs if DB is local' do
    reindex_command = 'runuser - postgres -c "reindexdb -a"'

    subject.stubs(:'execute!').with(reindex_command).returns(0)
    result = run_procedure(subject)
    assert result.success?, 'the procedure was expected to succeed'
  end
end
