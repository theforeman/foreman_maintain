module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulpcore
    end

    def run
      # use interactive to get realtime output
      puts execute!('foreman-rake katello:pulp3_migration', :interactive => true)
    end
  end
end
