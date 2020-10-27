module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulpcore

      confine do
        # FIXME: remove this condition on next downstream upgrade scenario
        !feature(:satellite) || feature(:satellite).at_least_version?('6.9')
      end
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration')
    end
  end
end
