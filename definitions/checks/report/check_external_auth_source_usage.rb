module Checks
  module Report
    class CheckExternalAuthSourceUsage < ForemanMaintain::ReportCheck
      metadata do
        description 'Checks the use of External auth source'
        tags :report
      end

      # Do you use external auth source?
      def run
        result = {}
        # nil means no user linked to external auth source ever logged in
        result["last_login_on_through_external_auth_source_in_days"] = nil

        users = feature(:foreman_database).query("SELECT users.* FROM users INNER JOIN auth_sources ON (auth_sources.id = users.auth_source_id) WHERE auth_sources.type = 'AuthSourceExternal' AND users.last_login_on IS NOT NULL ORDER BY users.last_login_on DESC")
        if (user = users.first)
          result["last_login_on_through_external_auth_source_in_days"] = (Date.today - Date.parse(user['last_login_on'])).to_i
        end

        self.data = result
      end
    end
  end
end
