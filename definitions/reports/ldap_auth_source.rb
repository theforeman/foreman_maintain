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
        result = %w[free_ipa posix active_directory].reduce({}) do |acc, flavor|
          acc.merge(flavor_usage(flavor))
        end

        count = feature(:foreman_database).query("external_usergroups")
        result["external_user_group_mapping_count"] = count.first['count'].to_i

        self.data = result
      end
    end

    private

    def flavor_usage(flavor)
      result = {}
      query_base = query_base(flavor)
      result["ldap_auth_source_#{flavor}_count"] = sql_count(query_base)

      users = feature(:foreman_database).query(user_query(flavor))
      result["users_authenticated_through_ldap_auth_source_#{flavor}"] = users.count

      result["last_login_on_through_ldap_auth_source_#{flavor}_in_days"] = last_login(users)

      result["ldap_auth_source_#{flavor}_with_net_groups_count"] =
        sql_count("#{query_base} AND use_netgroups = true")

      result["ldap_auth_source_#{flavor}_with_posix_groups_count"] =
        sql_count("#{query_base} AND use_netgroups = false")

      count = sql_count("#{query_base} AND onthefly_register = false")
      result["ldap_auth_source_#{flavor}_with_account_creation_disabled_count"] = count

      count = sql_count("#{query_base} AND usergroup_sync = false")
      result["ldap_auth_source_#{flavor}_with_user_group_sync_disabled_count"] = count

      result
    end

    def last_login(users)
      # nil means no user for a given LDAP type was found
      if (user = users.first)
        (Date.today - Date.parse(user['last_login_on'])).to_i
      end
    end

    def query_base(flavor)
      <<~SQL
        auth_sources
        WHERE auth_sources.type = 'AuthSourceLdap' AND auth_sources.server_type = '#{flavor}'
      SQL
    end

    def user_query(flavor)
      <<~SQL
        SELECT users.* FROM users
        INNER JOIN auth_sources ON (auth_sources.id = users.auth_source_id)
        WHERE auth_sources.type = 'AuthSourceLdap'
          AND auth_sources.server_type = '#{flavor}'
          AND users.last_login_on IS NOT NULL
        ORDER BY users.last_login_on DESC
      SQL
    end
  end
end
