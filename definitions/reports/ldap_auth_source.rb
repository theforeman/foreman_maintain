module Reports
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
      self.data = {}
      data_field("external_user_group_mapping_count") { sql_count('external_usergroups') }
      %w[free_ipa posix active_directory].reduce({}) do |_acc, flavor|
        record_flavor_usage(flavor)
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    def record_flavor_usage(flavor)
      flavored_query_base = query_base(flavor)
      data["ldap_auth_source_#{flavor}_count"] = sql_count(flavored_query_base)

      users = query(user_query(flavor))
      data["users_authenticated_through_ldap_auth_source_#{flavor}"] = users.count

      data["last_login_on_through_ldap_auth_source_#{flavor}_in_days"] = last_login(users)

      data["ldap_auth_source_#{flavor}_with_net_groups_count"] =
        sql_count("#{flavored_query_base} AND use_netgroups = true")

      data["ldap_auth_source_#{flavor}_with_posix_groups_count"] =
        sql_count("#{flavored_query_base} AND use_netgroups = false")

      count = sql_count("#{flavored_query_base} AND onthefly_register = false")
      data["ldap_auth_source_#{flavor}_with_account_creation_disabled_count"] = count

      count = sql_count("#{flavored_query_base} AND usergroup_sync = false")
      data["ldap_auth_source_#{flavor}_with_user_group_sync_disabled_count"] = count
    end
    # rubocop:enable Metrics/AbcSize

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
