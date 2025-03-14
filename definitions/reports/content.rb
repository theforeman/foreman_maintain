module Checks
  module Report
    class Content < ForemanMaintain::Report
      metadata do
        description 'Facts about Katello content'
        confine do
          feature(:katello)
        end
      end

      def run
        data_field('custom_library_yum_repositories_count') { custom_library_yum_repositories }
        data_field('redhat_library_yum_repositories_count') { redhat_library_yum_repositories }
        data_field('library_debian_repositories_count') { library_debian_repositories }
        data_field('library_container_repositories_count') { library_container_repositories }
        data_field('library_file_repositories_count') { library_file_repositories }
        data_field('library_python_repositories_count') { library_python_repositories }
        data_field('library_ansible_collection_repositories_count') do
          library_ansible_collection_repositories
        end
        data_field('library_ostree_repositories_count') { library_ostree_repositories }
      end

      def custom_library_yum_repositories
        query =
          query(
            <<-SQL
              SELECT count(*) as yum_custom_count FROM "katello_root_repositories"
                WHERE "katello_root_repositories"."id" NOT IN
                (SELECT "katello_root_repositories"."id" FROM "katello_root_repositories" INNER JOIN "katello_products"
                  ON "katello_products"."id" = "katello_root_repositories"."product_id" INNER JOIN "katello_providers"
                  ON "katello_providers"."id" = "katello_products"."provider_id" WHERE "katello_providers"."provider_type" = 'Red Hat')
                AND "katello_root_repositories"."content_type" = 'yum'
            SQL
          )
        query.first['yum_custom_count'].to_i
      end

      def redhat_library_yum_repositories
        query =
          query(
            <<-SQL
              SELECT count(*) as yum_rh_count FROM "katello_root_repositories"
                INNER JOIN "katello_products" ON "katello_products"."id" = "katello_root_repositories"."product_id"
                INNER JOIN "katello_providers" ON "katello_providers"."id" = "katello_products"."provider_id"
                  WHERE "katello_providers"."provider_type" = 'Red Hat'
                AND "katello_root_repositories"."content_type" = 'yum'
            SQL
          )
        query.first['yum_rh_count'].to_i
      end

      def library_container_repositories
        sql_count("katello_root_repositories WHERE content_type = 'docker'")
      end

      def library_ostree_repositories
        sql_count("katello_root_repositories WHERE content_type = 'ostree'")
      end

      def library_ansible_collection_repositories
        sql_count("katello_root_repositories WHERE content_type = 'ansible_collection'")
      end

      def library_file_repositories
        sql_count("katello_root_repositories WHERE content_type = 'file'")
      end

      def library_python_repositories
        sql_count("katello_root_repositories WHERE content_type = 'python'")
      end

      def library_debian_repositories
        sql_count("katello_root_repositories WHERE content_type = 'deb'")
      end
    end
  end
end
