module ForemanMaintain
  module Concerns
    module BaseDatabase
      def configuration
        raise NotImplementedError
      end

      def query(sql, config = configuration)
        parse_csv(query_csv(sql, config))
      end

      def query_csv(sql, config = configuration)
        psql(%{COPY (#{sql}) TO STDOUT WITH CSV HEADER}, config)
      end

      def psql(query, config = configuration)
        execute("PGPASSWORD='#{config[%(password)]}' #{psql_db_connection_str(config)}",
                :stdin => query)
      end

      def ping(config = configuration)
        psql('SELECT 1 as ping', config)
      end

      private

      def psql_db_connection_str(config)
        "psql -d #{config['database']} -h #{config['host'] || 'localhost'} "\
        " -p #{config['port'] || '5432'} -U #{config['username']}"
      end
    end
  end
end
