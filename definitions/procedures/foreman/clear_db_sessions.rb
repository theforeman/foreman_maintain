module Procedures::Foreman
  class ClearDBSessions < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_server
      advanced_run false
      description 'Clear sessions in database'
    end

    def run
      feature(:foreman_server).rake!('db:sessions:clear')
    end
  end
end
