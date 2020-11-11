module Procedures::Content
  class MigrationStats < ForemanMaintain::Procedure
    metadata do
      description 'Retrieve Pulp 2 to Pulp 3 migration statistics'
      for_feature :pulpcore

      confine do
        # FIXME: remove this condition on next downstream upgrade scenario
        !feature(:satellite) || feature(:satellite).at_least_version?('6.9')
      end
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration_stats')
    end
  end
end
