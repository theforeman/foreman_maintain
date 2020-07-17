module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulpcore

      confine do
        # FIXME: remove this condition on next downstream upgrade scenario
        !feature(:instance).downstream
      end
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration')
    end
  end
end
