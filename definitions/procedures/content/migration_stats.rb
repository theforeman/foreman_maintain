module Procedures::Content
  class MigrationStats < ForemanMaintain::Procedure
    metadata do
      description 'Retrieve Pulp 2 to Pulp 3 migration statistics'
      for_feature :pulpcore
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration_stats')
    end
  end
end
