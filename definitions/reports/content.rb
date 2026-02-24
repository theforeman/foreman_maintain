module Report
  class Content < ForemanMaintain::Report
    metadata do
      description 'Report metrics related to Katello content'
      confine do
        feature(:katello)
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/LineLength
    def run
      data_field('custom_library_yum_repositories_count') { custom_library_yum_repositories_count }
      data_field('redhat_library_yum_repositories_count') { redhat_library_yum_repositories_count }
      data_field('library_debian_repositories_count') { library_repositories_count('deb') }
      data_field('library_container_repositories_count') { library_repositories_count('docker') }
      data_field('library_file_repositories_count') { library_repositories_count('file') }
      data_field('library_python_repositories_count') { library_repositories_count('python') }
      data_field('library_ansible_collection_repositories_count') { library_repositories_count('ansible_collection') }
      data_field('library_ostree_repositories_count') { library_repositories_count('ostree') }
      data_field('redhat_repositories_enabled_count') { redhat_repositories_enabled_count }
      data_field('redhat_file_repositories_enabled_count') { redhat_file_repositories_enabled_count }
      merge_data('redhat_yum_repositories_architecture_count') { redhat_yum_repositories_architecture_count }
      data_field('flatpak_remotes_count') { sql_count("katello_flatpak_remotes") }
      data_field('flatpak_remote_repositories_count') { sql_count("katello_flatpak_remote_repositories") }
      data_field('flatpak_images_count') { sql_count("katello_flatpak_remote_repository_manifests") }
      data_field('rpms_count') { sql_count('katello_rpms') }
      data_field('errata_count') { sql_count('katello_errata') }
      data_field('module_streams_count') { sql_count('katello_module_streams') }
      data_field('file_units_count') { sql_count('katello_files') }
      data_field('ansible_collections_count') { sql_count('katello_ansible_collections') }
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/LineLength

    private

    def custom_library_yum_repositories_count
      query_snippet =
        <<-SQL
          "katello_root_repositories"
            WHERE "katello_root_repositories"."id" NOT IN
            (SELECT "katello_root_repositories"."id" FROM "katello_root_repositories" INNER JOIN "katello_products"
              ON "katello_products"."id" = "katello_root_repositories"."product_id" INNER JOIN "katello_providers"
              ON "katello_providers"."id" = "katello_products"."provider_id" WHERE "katello_providers"."provider_type" = 'Red Hat')
            AND "katello_root_repositories"."content_type" = 'yum'
        SQL
      sql_count(query_snippet)
    end

    def redhat_library_yum_repositories_count
      query_snippet =
        <<-SQL
          "katello_root_repositories"
            INNER JOIN "katello_products" ON "katello_products"."id" = "katello_root_repositories"."product_id"
            INNER JOIN "katello_providers" ON "katello_providers"."id" = "katello_products"."provider_id"
              WHERE "katello_providers"."provider_type" = 'Red Hat'
            AND "katello_root_repositories"."content_type" = 'yum'
        SQL
      sql_count(query_snippet)
    end

    def library_repositories_count(content_type)
      sql_count("katello_root_repositories WHERE content_type = '#{content_type}'")
    end

    def redhat_repositories_enabled_count
      sql_as_count(
        "COUNT(DISTINCT r.id)",
        <<~SQL
          katello_repositories r
          INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
          INNER JOIN katello_products p ON rr.product_id = p.id
          INNER JOIN katello_providers prov ON p.provider_id = prov.id
          INNER JOIN katello_content_view_versions cvv ON r.content_view_version_id = cvv.id
          INNER JOIN katello_content_views cv ON cvv.content_view_id = cv.id
          INNER JOIN katello_environments e ON r.environment_id = e.id
          WHERE prov.provider_type = 'Red Hat'
            AND cv.default = true
            AND e.library = true
            AND r.library_instance_id IS NULL
        SQL
      )
    end

    def redhat_file_repositories_enabled_count
      sql_count(
        <<-SQL
          katello_repositories r
          INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
          INNER JOIN katello_products p ON rr.product_id = p.id
          INNER JOIN katello_providers prov ON p.provider_id = prov.id
          INNER JOIN katello_content_view_versions cvv ON r.content_view_version_id = cvv.id
          INNER JOIN katello_content_views cv ON cvv.content_view_id = cv.id
          INNER JOIN katello_environments e ON r.environment_id = e.id
          WHERE prov.provider_type = 'Red Hat'
            AND cv.default = true
            AND e.library = true
            AND r.library_instance_id IS NULL
            AND rr.content_type = 'file'
        SQL
      )
    end

    def redhat_yum_repositories_architecture_count
      query(
        <<-SQL
          SELECT rr.arch, COUNT(*) AS repo_count
          FROM katello_repositories r
          INNER JOIN katello_root_repositories rr ON r.root_id = rr.id
          INNER JOIN katello_products p ON rr.product_id = p.id
          INNER JOIN katello_providers prov ON p.provider_id = prov.id
          INNER JOIN katello_content_view_versions cvv ON r.content_view_version_id = cvv.id
          INNER JOIN katello_content_views cv ON cvv.content_view_id = cv.id
          INNER JOIN katello_environments e ON r.environment_id = e.id
          WHERE prov.provider_type = 'Red Hat'
            AND cv.default = true
            AND e.library = true
            AND r.library_instance_id IS NULL
            AND rr.content_type = 'yum'
            AND rr.arch IS NOT NULL
          GROUP BY rr.arch
          ORDER BY rr.arch
        SQL
      ).to_h { |row| [row['arch'], row['repo_count'].to_i] }
    end
  end
end
