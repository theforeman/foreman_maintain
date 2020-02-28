module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulpcore
    end

    def run
      puts execute!('foreman-rake katello:pulp3_migration')
    end
  end
end
