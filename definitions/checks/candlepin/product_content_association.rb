module Checks
  module Candlepin
    class ProductContentAssociation < ForemanMaintain::Check
      metadata do
        description 'Make sure Product to Repository association in Candlepin DB is complete'
        label :candlepin_prod_repo_assoc
        tags :post_upgrade
        for_feature :candlepin_database
      end

      def missing_cp_associations
        feature(:candlepin_database).query(<<~SQL)
          SELECT c.content_id, c.uuid, c.name
            FROM cp2_content c
            JOIN cp2_owner_content oc ON c.uuid=oc.content_uuid
            LEFT OUTER JOIN (
              SELECT pc.content_uuid
                FROM cp2_products p
                JOIN cp2_owner_products op ON p.uuid=op.product_uuid
                JOIN cp2_product_content pc ON p.uuid=pc.product_uuid
            ) x ON c.uuid = x.content_uuid
            WHERE x.content_uuid IS NULL
        SQL
      end

      def run
        missing = missing_cp_associations

        assert(missing.empty?,
          "Candlepin DB is missing some Product to Content associations!\n" \
          "Found #{missing.length} content entries with missing product association.",
          :next_steps => [Procedures::Candlepin::ProductContentAssociation.new])
      end
    end
  end
end
