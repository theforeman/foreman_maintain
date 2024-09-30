module Checks
  module Report
    class LDAPAuthSource < ForemanMaintain::Report
      metadata do
        description 'Checks the use of LDAP auth sources'
      end

      # Do you use FreeIPA LDAP auth source?
      # Do you use AD LDAP auth source?
      # Do you use POSIX LDAP auth source?
      # Do you use netgroups schema?
      # Do you disable automatic account creation on any LDAP auth source?
      # Do you disable user group syncrhonization on any LDAP auth source?
      # Do you have external user groups mapping?
      def run
        result = {}

        %w[free_ipa posix active_directory].each do |flavor|
          count = sql_count("SELECT COUNT(*) FROM auth_sources WHERE auth_sources.type = 'AuthSourceLdap' AND server_type = '#{flavor}'")
          result["ldap_auth_source_#{flavor}_count"] = count

          users = feature(:foreman_database).query("SELECT users.* FROM users INNER JOIN auth_sources ON (auth_sources.id = users.auth_source_id) WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}' AND users.last_login_on IS NOT NULL ORDER BY users.last_login_on DESC")
          result["users_authenticated_through_ldap_auth_source_#{flavor}"] = users.count
          # nil means no user for a given LDAP type was found
          if (user = users.first)
            result["last_login_on_through_ldap_auth_source_#{flavor}_in_days"] =
              (Date.today - Date.parse(user['last_login_on'])).to_i
          else
            result["last_login_on_through_ldap_auth_source_#{flavor}_in_days"] = nil
          end

          count = sql_count("SELECT COUNT(*) FROM auth_sources WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}' AND use_netgroups = true")
          result["ldap_auth_source_#{flavor}_with_net_groups_count"] = count

          count = sql_count("SELECT COUNT(*) FROM auth_sources WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}' AND use_netgroups = false")
          result["ldap_auth_source_#{flavor}_with_posix_groups_count"] = count

          count = sql_count("SELECT COUNT(*) FROM auth_sources WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}' AND onthefly_register = false")
          result["ldap_auth_source_#{flavor}_with_account_creation_disabled_count"] = count

          count = sql_count("SELECT COUNT(*) FROM auth_sources WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}' AND usergroup_sync = false")
          result["ldap_auth_source_#{flavor}_with_user_group_sync_disabled_count"] = count
        end

        count = feature(:foreman_database).query("SELECT COUNT(*) FROM external_usergroups")
        result["external_user_group_mapping_count"] = count.first['count'].to_i

        self.data = result
      end
    end
  end
end
