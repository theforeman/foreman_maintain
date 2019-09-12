module Procedures::ForemanProxy
  class Features < ForemanMaintain::Procedure
    metadata do
      param :load_only, 'Do not print the features', :default => false
      description 'Detect features available in the local proxy'

      confine do
        feature(:instance).proxy_feature
      end
    end

    def run
      features = feature(:instance).proxy_feature.refresh_features
      puts features.join(', ') unless @load_only
    end
  end
end
