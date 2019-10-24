module Procedures::ForemanProxy
  class Features < ForemanMaintain::Procedure
    metadata do
      param :load_only, 'Do not print the features', :default => false
      description 'Detect features available in the local proxy'

      confine do
        feature(:foreman_proxy)
      end
    end

    def run
      features = feature(:foreman_proxy).refresh_features
      puts features.join(', ') unless @load_only
    end
  end
end
