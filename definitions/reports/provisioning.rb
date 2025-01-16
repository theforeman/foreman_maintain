module Checks
  module Report
    class Provisioning < ForemanMaintain::Report
      metadata do
        description 'Provisioning facts about the system'
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
      def run
        hosts_in_3_months =
          sql_count(
            <<-SQL
              hosts WHERE managed = true AND created_at >= current_date - interval '3 months'
            SQL
          )

        # Compute resources
        compute_resources_by_type =
          feature(:foreman_database).
          query(
            <<-SQL
              select type, count(*)
              from compute_resources
              group by type
            SQL
          ).
          to_h { |row| [row['type'], row['count'].to_i] }

        hosts_by_compute_resources_type =
          feature(:foreman_database).
          query(
            <<-SQL
              select compute_resources.type, count(hosts.id)
              from hosts left outer join compute_resources on compute_resource_id = compute_resources.id
              group by compute_resources.type
            SQL
          ).
          to_h { |row| [row['type'] || 'baremetal', row['count'].to_i] }
        hosts_by_compute_profile =
          feature(:foreman_database).
          query(
            <<-SQL
              select max(compute_profiles.name) as name, count(hosts.id)
              from hosts left outer join compute_profiles on compute_profile_id = compute_profiles.id
              group by compute_profile_id
            SQL
          ).
          to_h { |row| [row['name'] || 'none', row['count'].to_i] }

        # Bare metal
        nics_by_type_count =
          feature(:foreman_database).
          query(
            <<-SQL
              select type, count(*)
              from nics
              group by type
            SQL
          ).
          to_h { |row| [(row['type'] || 'none').sub('Nic::', ''), row['count'].to_i] }
        discovery_rules_count = sql_count('discovery_rules')
        hosts_by_managed_count =
          feature(:foreman_database).
          query(
            <<-SQL
              select managed, count(*)
              from hosts
              group by managed
            SQL
          ).
          to_h { |row| [row['managed'] == 't' ? 'managed' : 'unmanaged', row['count'].to_i] }

        # Templates
        non_default_templates_per_type =
          feature(:foreman_database).
          query(
            <<-SQL
              select type, count(*) from templates
              where templates.default = false
              group by type
            SQL
          ).
          to_h { |row| [row['type'], row['count'].to_i] }

        data = {
          discovery_rules_count: discovery_rules_count,
          managed_hosts_created_in_last_3_months: hosts_in_3_months,
        }
        data.merge!(flatten(compute_resources_by_type, 'compute_resources_by_type'))
        data.merge!(flatten(hosts_by_compute_resources_type, 'hosts_by_compute_resources_type'))
        data.merge!(flatten(hosts_by_compute_profile, 'hosts_by_compute_profile'))
        data.merge!(flatten(nics_by_type_count, 'nics_by_type'))
        data.merge!(flatten(hosts_by_managed_count, 'managed_hosts_count'))
        data.merge!(flatten(non_default_templates_per_type, 'non_default_templates_per_type'))

        self.data = data
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    end
  end
end
