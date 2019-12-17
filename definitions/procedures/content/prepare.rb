module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulp3
    end

    def run
      execute!('foreman-rake katello:pulp3_migration')
    end
  end
end
