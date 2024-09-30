module Checks
  module Report
    class Kerberos < ForemanMaintain::Report
      metadata do
        description 'Checks the use of Kerberos'
        tags :report
      end

      # Do you use kerberos?
      # Do you use kerberos also for API authentication?
      def run
        authorize_login_delegation = feature(:foreman_database).query("SELECT value FROM settings WHERE name = 'authorize_login_delegation'").first
        authorize_login_delegation_api = feature(:foreman_database).query("SELECT value FROM settings WHERE name = 'authorize_login_delegation_api'").first
        oidc_issuer = feature(:foreman_database).query("SELECT value FROM settings WHERE name = 'oidc_issuer'").first
        kerberos_result = authorize_login_delegation && YAML.load(authorize_login_delegation['value']) == true &&
                          (oidc_issuer.nil? || YAML.load(oidc_issuer['value']) == '')
        kerberos_api_result = kerberos_result && authorize_login_delegation_api && YAML.load(authorize_login_delegation_api['value']) == true

        self.data = {
          kerberos_use: !!kerberos_result,
          kerberos_api_use: !!kerberos_api_result,
        }
      end
    end
  end
end
