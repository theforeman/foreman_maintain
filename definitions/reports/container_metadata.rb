module Report
  class ContainerMetadata < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello container metadata'
      confine do
        feature(:katello)
      end
    end

    def run
      data_field('container_manifests_count') { container_manifests_count }
      data_field('container_manifest_lists_count') { container_manifest_lists_count }
      data_field('container_tags_count') { container_tags_count }
      data_field('container_meta_tags_count') { container_meta_tags_count }
    end

    private

    def container_manifests_count
      # Count distinct container manifests present in container repositories.
      # Exclude flatpaks which also use the manifest tables.
      sql = <<-SQL
        katello_repository_docker_manifests rdm
        INNER JOIN katello_docker_manifests dm ON rdm.docker_manifest_id = dm.id
        INNER JOIN katello_repositories r ON rdm.repository_id = r.id
        INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
        WHERE rr.content_type = 'docker'
          AND COALESCE(dm.is_flatpak, false) = false
      SQL
      sql_count(sql, column: 'DISTINCT dm.id')
    end

    def container_manifest_lists_count
      sql = <<-SQL
        katello_repository_docker_manifest_lists rdml
        INNER JOIN katello_repositories r ON rdml.repository_id = r.id
        INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
        WHERE rr.content_type = 'docker'
      SQL
      sql_count(sql, column: 'DISTINCT rdml.docker_manifest_list_id')
    end

    def container_tags_count
      sql = <<-SQL
        katello_repository_docker_tags rdt
        INNER JOIN katello_repositories r ON rdt.repository_id = r.id
        INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
        WHERE rr.content_type = 'docker'
      SQL
      sql_count(sql)
    end

    def container_meta_tags_count
      sql = <<-SQL
        katello_repository_docker_meta_tags rdmt
        INNER JOIN katello_repositories r ON rdmt.repository_id = r.id
        INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
        WHERE rr.content_type = 'docker'
      SQL
      sql_count(sql)
    end
  end
end
