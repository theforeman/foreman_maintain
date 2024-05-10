module Checks
  module Report
    class CheckLDAPAuthSourceUsage < ForemanMaintain::Check
      metadata do
        description 'Checks the use of LDAP auth sources'
        tags :report
      end

      # Do you use FreeIPA LDAP auth source?
      # Do you use AD LDAP auth source?
      # Do you use POSIX LDAP auth source?
      def run
        result = {}

        %w(free_ipa posix active_directory).each do |flavor|
          count = feature(:foreman_database).query("SELECT COUNT(*) FROM auth_sources WHERE auth_sources.type = 'AuthSourceLdap' AND server_type = '#{flavor}'")
          result["ldap_auth_source_#{flavor}_count"] = count.first['count'].to_i

          users = feature(:foreman_database).query("SELECT users.* FROM users INNER JOIN auth_sources ON (auth_sources.id = users.auth_source_id) WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}' AND users.last_login_on IS NOT NULL ORDER BY users.last_login_on DESC")
          result["users_authenticated_through_ldap_auth_source_#{flavor}"] = users.count
          # nil means no user for a given LDAP type was found
          if (user = users.first)
            result["last_login_on_through_ldap_auth_source_#{flavor}_in_days"] = (Date.today - Date.parse(user['last_login_on'])).to_i
          else
            result["last_login_on_through_ldap_auth_source_#{flavor}_in_days"] = nil
          end
        end

        self.data = result
      end
    end
  end
end
