module Procedures::Foreman
  class ApipieCache < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Regenerate Apipie cache'
    end

    def run
      execute!('foreman-rake apipie:cache')
    end
  end
end
