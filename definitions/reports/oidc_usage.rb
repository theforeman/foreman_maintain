module Checks
  module Report
    class OIDC < ForemanMaintain::Report
      metadata do
        description 'Checks the use of Keycloak/OIDC'
      end

      # Do you use OIDC/keycloak?
      def run
        oidc_issuer = sql_setting('oidc_issuer')
        result = if oidc_issuer
                   loaded = YAML.load(oidc_issuer)
                   loaded.is_a?(String) && loaded != ''
                 end

        self.data = { oidc_use: !!result }
      end
    end
  end
end
