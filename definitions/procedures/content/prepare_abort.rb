module Procedures::Content
  class PrepareAbort < ForemanMaintain::Procedure
    metadata do
      description 'Abort all running Pulp 2 to Pulp 3 migration tasks'
      for_feature :pulpcore

      confine do
        # FIXME: remove this condition on next downstream upgrade scenario
        !feature(:satellite) || feature(:satellite).at_least_version?('6.9')
      end
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration_abort')
    end
  end
end
