module Checks
  module Report
    class ExternalAuthSource < ForemanMaintain::Report
      metadata do
        description 'Checks the use of External auth source'
      end

      # Do you use external auth source?
      def run
        self.data = {}
        # nil means no user linked to external auth source ever logged in
        data["last_login_on_through_external_auth_source_in_days"] = nil

        sql = <<~SQL
          SELECT users.* FROM users
          INNER JOIN auth_sources ON (auth_sources.id = users.auth_source_id)
          WHERE auth_sources.type = 'AuthSourceExternal' AND users.last_login_on IS NOT NULL
          ORDER BY users.last_login_on DESC
        SQL
        users = feature(:foreman_database).query(sql)
        if (user = users.first)
          data["last_login_on_through_external_auth_source_in_days"] =
            (Date.today - Date.parse(user['last_login_on'])).to_i
        end
      end
    end
  end
end
