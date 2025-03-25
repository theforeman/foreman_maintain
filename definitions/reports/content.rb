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
        data_field('library_debian_repositories_count') { library_repositories('deb') }
        data_field('library_container_repositories_count') { library_repositories('docker') }
        data_field('library_file_repositories_count') { library_repositories('file') }
        data_field('library_python_repositories_count') { library_repositories('python') }
        data_field('library_ansible_collection_repositories_count') do
          library_repositories('ansible_collection')
        end
        data_field('library_ostree_repositories_count') { library_repositories('ostree') }
      end

      def custom_library_yum_repositories
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

      def redhat_library_yum_repositories
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

      def library_repositories(content_type)
        sql_count("katello_root_repositories WHERE content_type = '#{content_type}'")
      end
    end
  end
end
