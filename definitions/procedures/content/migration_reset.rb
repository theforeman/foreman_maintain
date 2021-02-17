module Procedures::Content
  class MigrationReset < ForemanMaintain::Procedure
    metadata do
      description 'Reset the Pulp 2 to Pulp 3 migration data (pre-switchover)'
      for_feature :pulpcore
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration_reset')
    end
  end
end
