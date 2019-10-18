module Procedures::Foreman
  class DbMigrate < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_server
      advanced_run false
      description 'Apply database migrations'
    end

    def run
      feature(:foreman_server).rake!('db:migrate')
    end
  end
end
