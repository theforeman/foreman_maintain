module Procedures::Content
  class PrepareAbort < ForemanMaintain::Procedure
    metadata do
      description 'Abort all running Pulp 2 to Pulp 3 migration tasks'
      for_feature :pulpcore
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration_abort')
    end
  end
end
