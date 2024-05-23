module Checks
  module Report
    class OIDC < ForemanMaintain::Report
      metadata do
        description 'Checks the use of Keycloak/OIDC'
      end

      # Do you use OIDC/keycloak?
      def run
        oidc_issuer = feature(:foreman_database).query("SELECT value FROM settings WHERE name = 'oidc_issuer'").first
        result = (oidc_issuer && YAML.load(oidc_issuer['value']).is_a?(String) && YAML.load(oidc_issuer['value']) != '')

        self.data = { oidc_use: !!result }
      end
    end
  end
end
