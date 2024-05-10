module Checks
  module Report
    class CheckKerberosUsage < ForemanMaintain::Check
      metadata do
        description 'Checks the use of Kerberos'
        tags :report
      end

      # Do you use kerberos?
      def run
        authorize_login_delegation = feature(:foreman_database).query("SELECT value FROM settings WHERE name = 'authorize_login_delegation'").first
        oidc_issuer = feature(:foreman_database).query("SELECT value FROM settings WHERE name = 'oidc_issuer'").first
        result = authorize_login_delegation && YAML.load(authorize_login_delegation['value']) == true &&
          (oidc_issuer.nil? || YAML.load(oidc_issuer['value']) == '')

        self.data = { kerberos_use: result }
      end
    end
  end
end
