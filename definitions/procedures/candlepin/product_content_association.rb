require 'set'

module Procedures::Candlepin
  class ProductContentAssociation < ForemanMaintain::Procedure
    metadata do
      for_feature :candlepin_database
      description 'Reassociate Content to Product in CandlepinDB'
    end

    # returns a Hash of candlepin product cp_id keys with a Hash of queried values
    # consisting of the product's name and the number of associated content
    # e.g. { '<cp_id>' => { 'name' => '...', count => X, ..}, ... }
    def foreman_content_num_by_product
      feature(:foreman_database).query(<<~SQL).map { |e| [e['cp_id'], e] }.to_h
        SELECT p.cp_id as cp_id, p.name as name, COUNT(c.id) as count
          FROM katello_products p
          JOIN katello_product_contents pc ON p.id = pc.product_id
          JOIN katello_contents c ON pc.content_id = c.id
          GROUP BY p.cp_id, p.name
      SQL
    end

    # return Hash of query-result Hashes with the respective candlepin product_id as key
    # similar to foreman_content_num_by_product()
    def cp_content_count_by_product
      feature(:candlepin_database).query(<<~SQL).map { |e| [e['product_id'], e] }.to_h
        SELECT product.product_id, product.uuid, product.name, COUNT(content.content_id)
          FROM cp_pool pool
          JOIN cp2_products product ON pool.product_uuid = product.uuid
          LEFT JOIN cp2_product_content pc ON product.uuid = pc.product_uuid
          LEFT JOIN cp2_content content ON content.uuid = pc.content_uuid
          GROUP BY product.uuid
      SQL
    end

    # returns a set of cp2_content ids for given product_id
    def cp_product_content_ids(product_id)
      feature(:candlepin_database).query(<<~SQL).map { |e| e['content_id'] }.to_set
        SELECT content.content_id
          FROM cp_pool pool
          JOIN cp2_products product ON pool.product_uuid = product.uuid
          JOIN cp2_product_content pc ON product.uuid = pc.product_uuid
          JOIN cp2_content content ON content.uuid = pc.content_uuid
          WHERE product.product_id = '#{product_id}'
      SQL
    end

    # return Set of candlepin content ids from katello_content table
    # for candlepin product with cp_id
    def katello_content_ids(cp_id)
      feature(:foreman_database).query(<<~SQL).map { |e| e['cp_content_id'] }.to_set
        SELECT c.cp_content_id
          FROM katello_products p
          JOIN katello_product_contents pc ON p.id = pc.product_id
          JOIN katello_contents c ON pc.content_id = c.id
          WHERE p.cp_id = '#{cp_id}'
      SQL
    end

    def assemble_restore_commands(look_closer_products)
      commands = []
      look_closer_products.each do |cp_id, product|
        puts "Process Product #{product['name'].inspect}"
        # get content_ids from candlepin and katello
        missing_ids = katello_content_ids(cp_id) - cp_product_content_ids(cp_id)

        missing_ids.each do |content_id|
          commands << create_new_association_sql_inserts(product['uuid'], content_id)

          # clear entity version of affected product to avoid versioning and convergence issues
          commands << 'UPDATE cp2_products SET entity_version = NULL ' \
            "WHERE uuid = '#{product['uuid']}'"
        end
      end
      commands
    end

    # returns SQL-INSERT String to recreate missing associations
    def create_new_association_sql_inserts(product_uuid, content_id)
      missing = feature(:candlepin_database).query(
        "SELECT name, uuid FROM cp2_content WHERE content_id = '#{content_id}'"
      )
      insert_sql = []
      missing.each do |content|
        puts "  - repair missing: #{content['name'].inspect}"
        insert_sql << "(REPLACE(uuid_in((md5((random())::text))::cstring)::text, '-', '' )," \
          ' true,' \
          " '#{product_uuid}'," \
          " '#{content['uuid']}'," \
          ' NOW(), NOW())'
      end

      <<~SQL
        INSERT INTO cp2_product_content
          (id, enabled, product_uuid, content_uuid, created, updated)
          VALUES #{insert_sql.join(', ')}
      SQL
    end

    def run
      candlepin_content_num_by_product = cp_content_count_by_product
      look_closer_products = {}

      foreman_content_num_by_product.each do |product_id, foreman_product|
        next unless candlepin_content_num_by_product.key?(product_id)

        candlepin_product = candlepin_content_num_by_product[product_id]
        next unless foreman_product['count'] != candlepin_product['count']

        look_closer_products[product_id] = candlepin_product
      end

      res = feature(:candlepin_database).psql(<<~SQL)
        BEGIN;
          #{assemble_restore_commands(look_closer_products).join(";\n")};
        COMMIT;
      SQL

      if res.include? 'ERROR'
        warn! "Repairing Product-Content association in CandlepinDB failed. Please check the logs."
      end
    end
  end
end
