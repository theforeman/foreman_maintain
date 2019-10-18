module Procedures::Foreman
  class DbSeed < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_server
      advanced_run false
      description 'Update default values seed in the database'
    end

    def run
      feature(:foreman_server).rake!('db:seed')
    end
  end
end
