module Report
  class LifecycleEnvironments < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello lifecycle environments'
      confine do
        feature(:katello)
      end
    end

    def run
      data_field('lifecycle_environments_count') { lifecycle_environments_count }
      data_field('lifecycle_environment_paths_count') { lifecycle_environment_paths_count }
      data_field('registry_name_patterns_count') { registry_name_patterns_count }
    end

    private

    def lifecycle_environments_count
      sql_count("katello_environments WHERE library = false")
    end

    # rubocop:disable Metrics/MethodLength
    def lifecycle_environment_paths_count
      # A path is defined as a complete chain from the Library environment to a leaf environment
      # (per organization). We count distinct leaf environments reachable from each org's Library.
      env_paths_cte = <<~SQL
        WITH RECURSIVE env_tree AS (
          SELECT e.id, e.organization_id
          FROM katello_environments e
          WHERE e.library = true
          UNION ALL
          SELECT child.id, child.organization_id
          FROM env_tree parent
          INNER JOIN katello_environment_priors p ON p.prior_id = parent.id
          INNER JOIN katello_environments child ON child.id = p.environment_id
        ), leaf_envs AS (
          SELECT t.id, t.organization_id
          FROM env_tree t
          INNER JOIN katello_environments e ON e.id = t.id
          LEFT JOIN katello_environment_priors p ON p.prior_id = t.id
          WHERE p.prior_id IS NULL
            AND e.library = false
        ), distinct_leaf_envs AS (
          SELECT DISTINCT organization_id, id FROM leaf_envs
        )
      SQL
      sql_count('distinct_leaf_envs', cte: env_paths_cte)
    end
    # rubocop:enable Metrics/MethodLength

    def registry_name_patterns_count
      sql_count(<<-SQL)
        katello_environments
        WHERE registry_name_pattern IS NOT NULL
          AND registry_name_pattern != ''
      SQL
    end
  end
end
