module ForemanMaintain
  module Concerns
    module BaseDatabase
      def data_dir
        if debian_or_ubuntu?
          deb_postgresql_data_dir
        else
          '/var/lib/pgsql/data/'
        end
      end

      def deb_postgresql_data_dir
        deb_postgresql_versions.map do |ver|
          "/var/lib/postgresql/#{ver}/main/"
        end
      end

      def deb_postgresql_versions
        @deb_postgresql_versions ||= begin
          installed_pkgs = package_manager.list_installed_packages('${binary:Package}\n')
          installed_pkgs.grep(/^postgresql-\d+$/).map do |name|
            name.split('-').last
          end
        end
      end

      def postgresql_conf
        return "#{data_dir}/postgresql.conf" if el?

        deb_postgresql_config_dirs.map do |conf_dir|
          "#{conf_dir}postgresql.conf"
        end
      end

      def deb_postgresql_config_dirs
        deb_postgresql_versions.map do |ver|
          "/etc/postgresql/#{ver}/main/"
        end
      end

      def configuration
        raise NotImplementedError
      end

      def local?(config = configuration)
        ['localhost', '127.0.0.1', `hostname`.strip].include?(configuration['host']) ||
          config['host'].nil?
      end

      def query(sql)
        parse_csv(query_csv(sql))
      end

      def query_csv(sql)
        psql(%{COPY (#{sql}) TO STDOUT WITH CSV HEADER})
      end

      def psql(query)
        ping!

        if local?
          execute("runuser - postgres -c 'psql -d #{configuration['database']}' -c '#{query}'")
        else
          execute('psql',
            :stdin => query,
            :env => base_env)
        end
      end

      def ping
        if local?
          command = "runuser - postgres -c 'psql -d #{configuration['database']}'"
          env = nil
        else
          command = 'psql'
          env = base_env
        end
        execute?(command, stdin: 'SELECT 1 as ping', env: env)
      end

      def dump_db(file)
        if local?
          dump_command = "pg_dump --format=c #{configuration['connection_string']}"
          execute!("chown -R postgres:postgres #{File.dirname(file)}")
          execute!("runuser - postgres -c '#{dump_command} -f #{file}'")
        else
          dump_command = "pg_dump -Fc -f #{file}"
          execute!(dump_command, :env => base_env)
        end
      end

      def restore_dump(file, localdb)
        if localdb
          dump_cmd = "runuser - postgres -c 'pg_restore -C -d postgres #{file}'"
          execute!(dump_cmd)
        else
          # TODO: figure out how to completely ignore errors. Currently this
          # sometimes exits with 1 even though errors are ignored by pg_restore
          dump_cmd = 'pg_restore --no-privileges --clean --disable-triggers -n public ' \
                     "-d #{configuration['database']} #{file}"
          execute!(dump_cmd, :env => base_env,
            :valid_exit_statuses => [0, 1])
        end
      end

      def backup_local(backup_file, extra_tar_options = {})
        dir = extra_tar_options.fetch(:data_dir, data_dir)
        restore_dir = extra_tar_options.fetch(:restore_dir, data_dir)
        command = extra_tar_options.fetch(:command, 'create')

        FileUtils.cd(dir) do
          tar_options = {
            :archive => backup_file,
            :command => command,
            :transform => "s,^,#{restore_dir[1..]},S",
            :files => '*',
          }.merge(extra_tar_options)
          feature(:tar).run(tar_options)
        end
      end

      # TODO: remove the backup file path tools from here. Lib Utils::Backup?
      def backup_dir
        @backup_dir ||= File.expand_path(ForemanMaintain.config.db_backup_dir)
      end

      def dropdb
        if local?
          execute!("runuser - postgres -c 'dropdb #{configuration['database']}'")
        else
          delete_statement = psql(<<~SQL)
            select string_agg('drop table if exists \"' || tablename || '\" cascade;', '')
            from pg_tables
            where schemaname = 'public';
          SQL
          psql(delete_statement)
        end
      end

      def db_version
        ping!

        query = 'SHOW server_version'
        server_version_cmd = 'psql --tuples-only --no-align'
        version_string = if local?
                           execute!("runuser - postgres -c '#{server_version_cmd} -c \"#{query}\"'")
                         else
                           execute!(server_version_cmd, :stdin => query, :env => base_env)
                         end
        version(version_string)
      end

      def psql_cmd_available?
        exit_status, _output = execute_with_status('which psql')
        exit_status == 0
      end

      def raise_psql_missing_error
        raise Error::Fail, 'The psql command not found.'\
                ' Make sure system has psql utility installed.'
      end

      def amcheck
        # executing the check requires superuser privileges
        return unless local?

        return unless amcheck_installed?

        psqlcmd = "runuser - postgres -c 'psql --set=ON_ERROR_STOP=on #{configuration['database']}'"

        amcheck_query = <<~SQL
          SELECT bt_index_check(index => c.oid, heapallindexed => i.indisunique),
               c.relname,
               c.relpages
          FROM pg_index i
          JOIN pg_opclass op ON i.indclass[0] = op.oid
          JOIN pg_am am ON op.opcmethod = am.oid
          JOIN pg_class c ON i.indexrelid = c.oid
          JOIN pg_namespace n ON c.relnamespace = n.oid
          WHERE am.amname = 'btree' AND n.nspname = 'public'
          -- Don't check temp tables, which may be from another session:
          AND c.relpersistence != 't'
          -- Function may throw an error when this is omitted:
          AND c.relkind = 'i' AND i.indisready AND i.indisvalid
          ORDER BY c.relpages DESC;
        SQL

        execute_with_status(psqlcmd, :stdin => amcheck_query)
      end

      def amcheck_installed?
        sql = "select 'amcheck_installed' from pg_extension where extname='amcheck'"
        result = query(sql)
        !result.nil? && !result.empty?
      end

      private

      def base_env
        {
          'PGHOST' => configuration.fetch('host', 'localhost'),
          'PGPORT' => configuration['port']&.to_s,
          'PGUSER' => configuration['username'],
          'PGPASSWORD' => configuration['password'],
          'PGDATABASE' => configuration['database'],
        }
      end

      def ping!
        unless ping
          raise Error::Fail, 'Please check whether database service is up & running state.'
        end
      end
    end
  end
end
