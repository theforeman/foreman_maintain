module Checks
  module Report
    class Provisioning < ForemanMaintain::Report
      metadata do
        description 'Provisioning facts about the system'
      end

      def run
        hosts_in_3_months = sql_count("SELECT COUNT(*) FROM hosts WHERE managed = true AND created_at >= current_date - interval '3 months'")

        # Compute resources
        compute_resources_by_type = feature(:foreman_database).query("select type, count(*) from compute_resources group by type")

        hosts_by_compute_resources_type = feature(:foreman_database).query("select compute_resources.type, count(hosts.id) from hosts left outer join compute_resources on compute_resource_id = compute_resources.id group by compute_resources.type")
        hosts_by_compute_profile = feature(:foreman_database).query("select max(compute_profiles.name), count(hosts.id) from hosts left outer join compute_profiles on compute_profile_id = compute_profiles.id group by compute_profile_id")

        # Bare metal
        nics_by_type_count = feature(:foreman_database).query("select type, count(*) from nics group by type")
        discovery_rules_count = sql_count("select count(*) from discovery_rules")
        hosts_by_managed_count = feature(:foreman_database).query("select managed, count(*) from hosts group by managed")


        # Templates
        non_default_templates_per_type = feature(:foreman_database).query("select type, count(*) from templates where templates.default = false group by type")

        self.data = { managed_hosts_created_in_last_3_months: hosts_in_3_months }
      end
    end
  end
end
