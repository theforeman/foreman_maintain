module Reports
  class OIDC < ForemanMaintain::Report
    metadata do
      description 'Checks the use of Keycloak/OIDC'
    end

    # Do you use OIDC/keycloak?
    def run
      data_field('oidc_use') do
        oidc_issuer = sql_setting('oidc_issuer') || ''
        loaded = YAML.load(oidc_issuer)
        loaded.is_a?(String) && loaded != ''
      end
    end
  end
end
