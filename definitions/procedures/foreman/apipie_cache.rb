module Procedures::Foreman
  class ApipieCache < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Regenerate Apipie cache'
    end

    def run
      execute!('FOREMAN_APIPIE_LANGS=en foreman-rake apipie:cache')
    end
  end
end
