module Report
  module Table
    class Counts < ForemanMaintain::Report
      metadata do
        label :table_counts
        description 'Get table counts'
      end

      TABLES = %w[hosts dynflow_actions dynflow_steps katello_repositories].freeze

      def run
        puts "\n<table-name> : <records-found>"
        TABLES.each do |table|
          puts "#{table} : #{feature(:foreman_database).count(table)}"
        end
      end

      def to_h
        stats =
          TABLES.inject({}) do |stat, table|
            stat.merge(table => feature(:foreman_database).count(table))
          end

        { label => stats }
      end
    end
  end
end
