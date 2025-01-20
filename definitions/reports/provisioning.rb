module Reports
  class Provisioning < ForemanMaintain::Report
    metadata do
      description 'Provisioning facts about the system'
    end

    def run
      data_field('managed_hosts_created_in_last_3_months') do
        sql_count(
          <<-SQL
            hosts WHERE managed = true AND created_at >= current_date - interval '3 months'
          SQL
        )
      end

      compute_resources_fields
      bare_metal_fields
      templates_fields
    end

    def compute_resources_fields
      hosts_by_compute_resources_type
      hosts_by_compute_profile

      merge_data('compute_resources_by_type') do
        feature(:foreman_database).
          query(
            <<-SQL
              select type, count(*)
              from compute_resources
              group by type
            SQL
          ).
          to_h { |row| [row['type'], row['count'].to_i] }
      end
    end

    def hosts_by_compute_resources_type
      merge_data('hosts_by_compute_resources_type') do
        feature(:foreman_database).
          query(
            <<-SQL
              select compute_resources.type, count(hosts.id)
              from hosts left outer join compute_resources on compute_resource_id = compute_resources.id
              group by compute_resources.type
            SQL
          ).
          to_h { |row| [row['type'] || 'baremetal', row['count'].to_i] }
      end
    end

    def hosts_by_compute_profile
      merge_data('hosts_by_compute_profile') do
        feature(:foreman_database).
          query(
            <<-SQL
              select max(compute_profiles.name) as name, count(hosts.id)
              from hosts left outer join compute_profiles on compute_profile_id = compute_profiles.id
              group by compute_profile_id
            SQL
          ).
          to_h { |row| [row['name'] || 'none', row['count'].to_i] }
      end
    end

    def bare_metal_fields
      nics_by_type_count
      hosts_by_managed_count

      data_field('discovery_rules_count') { sql_count('discovery_rules') }
    end

    def nics_by_type_count
      merge_data('nics_by_type_count') do
        feature(:foreman_database).
          query(
            <<-SQL
              select type, count(*)
              from nics
              group by type
            SQL
          ).
          to_h { |row| [(row['type'] || 'none').sub('Nic::', ''), row['count'].to_i] }
      end
    end

    def hosts_by_managed_count
      merge_data('hosts_by_managed_count') do
        feature(:foreman_database).
          query(
            <<-SQL
              select managed, count(*)
              from hosts
              group by managed
            SQL
          ).
          to_h { |row| [row['managed'] == 't' ? 'managed' : 'unmanaged', row['count'].to_i] }
      end
    end

    def templates_fields
      merge_data('non_default_templates_per_type') do
        feature(:foreman_database).
          query(
            <<-SQL
              select type, count(*) from templates
              where templates.default = false
              group by type
            SQL
          ).
          to_h { |row| [row['type'], row['count'].to_i] }
      end
    end
  end
end
