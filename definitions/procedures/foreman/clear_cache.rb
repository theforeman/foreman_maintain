module Procedures::Foreman
  class ClearCache < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_server
      advanced_run false
      description 'Clear server cache'
    end

    def run
      feature(:foreman_server).rake!('tmp:cache:clear')
    end
  end
end
