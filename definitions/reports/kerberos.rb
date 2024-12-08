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
        authorize_login_delegation = sql_setting('authorize_login_delegation')
        authorize_login_delegation_api = sql_setting('authorize_login_delegation_api')
        oidc_issuer = sql_setting('oidc_issuer')
        kerberos_result = authorize_login_delegation &&
                          YAML.load(authorize_login_delegation) == true &&
                          (oidc_issuer.nil? || YAML.load(oidc_issuer) == '')
        kerberos_api_result = kerberos_result &&
                              authorize_login_delegation_api &&
                              YAML.load(authorize_login_delegation_api) == true

        self.data = {
          kerberos_use: !!kerberos_result,
          kerberos_api_use: !!kerberos_api_result,
        }
      end
    end
  end
end
