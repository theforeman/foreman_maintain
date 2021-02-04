module Procedures::Foreman
  class ApipieCache < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_server
      advanced_run false
      description 'Regenerate Apipie cache'
    end

    def run
      feature(:foreman_server).rake!('apipie:cache')
    end
  end
end
