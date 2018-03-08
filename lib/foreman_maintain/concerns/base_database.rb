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

      def backup_file_path(config = configuration)
        dump_file_name = "#{config['database']}_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.dump"
        "#{backup_dir}/#{dump_file_name}.bz2"
      end

      def backup_db_command(file_path, config = configuration)
        pg_dump_cmd = "pg_dump -Fc #{config['database']}"
        "runuser - postgres -c '#{pg_dump_cmd}' | bzip2 -9 > #{file_path}"
      end

      def backup_dir
        @backup_dir ||= File.expand_path(ForemanMaintain.config.db_backup_dir)
      end

      def perform_backup(config = configuration)
        file_path = backup_file_path(config)
        backup_cmd = backup_db_command(file_path, config)
        execute!(backup_cmd)
        puts "\n Note: Database backup file path - #{file_path}"
        puts "\n In case of any exception, use above dump file to restore DB."
      end

      def table_exist?(table_name)
        sql = <<-SQL
          SELECT EXISTS ( SELECT *
          FROM information_schema.tables WHERE table_name =  '#{table_name}' )
        SQL
        result = query(sql)
        return false if result.nil? || (result && result.empty?)
        result.first['exists'].eql?('t')
      end

      def delete_records_by_ids(tbl_name, rec_ids)
        quotize_rec_ids = rec_ids.map { |el| "'#{el}'" }.join(',')
        unless quotize_rec_ids.empty?
          psql(<<-SQL)
            BEGIN;
             DELETE FROM #{tbl_name} WHERE id IN (#{quotize_rec_ids});
            COMMIT;
          SQL
        end
      end

      private

      def psql_db_connection_str(config)
        "psql -d #{config['database']} -h #{config['host'] || 'localhost'} "\
        " -p #{config['port'] || '5432'} -U #{config['username']}"
      end
    end
  end
end
