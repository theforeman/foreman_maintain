module Checks
  module Foreman
    class FactsNames < ForemanMaintain::Check
      metadata do
        label :foreman_fact_names
        tags :default
        confine do
          feature(:foreman_database)
        end
        description 'Check number of fact names in database'
      end

      def run
        max = 10_000
        sql = <<-SQL
        select fact_values.host_id, count(fact_values.id) from fact_values
        group by fact_values.host_id order by count desc limit 1
        SQL
        result = feature(:foreman_database).query(sql).first
        if result
          host_id = result['host_id']
          count = result['count'].to_i
          assert(count < max,
                 "Host (ID #{host_id}) has #{count} fact values which is more than #{max}.\n" \
                 'This can cause slow fact processing.',
                 :warn => true,
                 :next_steps => [Procedures::KnowledgeBaseArticle.new(:doc => 'many_fact_values')])
        end
      end
    end
  end
end
