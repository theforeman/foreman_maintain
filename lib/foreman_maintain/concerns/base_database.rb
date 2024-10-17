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
        installed_pkgs = package_manager.list_installed_packages('${binary:Package}\n')
        @deb_postgresql_versions ||= installed_pkgs.grep(/^postgresql-\d+$/).map do |name|
          name.split('-').last
        end
        @deb_postgresql_versions
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

      def local?
        ['localhost', '127.0.0.1', `hostname`.strip].include?(configuration['host'])
      end

      def query(sql)
        parse_csv(query_csv(sql))
      end

      def query_csv(sql)
        psql(%{COPY (#{sql}) TO STDOUT WITH CSV HEADER})
      end

      def psql(query)
        if ping
          execute('psql',
            :stdin => query,
            :env => base_env)
        else
          raise_service_error
        end
      end

      def ping
        execute?('psql',
          :stdin => 'SELECT 1 as ping',
          :env => base_env)
      end

      def dump_db(file)
        dump_command = "pg_dump -Fc -f #{file}"
        execute!(dump_command, :env => base_env)
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
          delete_statement = psql(<<-SQL)
            select string_agg('drop table if exists \"' || tablename || '\" cascade;', '')
            from pg_tables
            where schemaname = 'public';
          SQL
          psql(delete_statement)
        end
      end

      def db_version
        if ping
          query = 'SHOW server_version'
          server_version_cmd = 'psql --tuples-only --no-align'
          version_string = execute!(server_version_cmd, :stdin => query, :env => base_env)
          version(version_string)
        else
          raise_service_error
        end
      end

      def psql_cmd_available?
        exit_status, _output = execute_with_status('which psql')
        exit_status == 0
      end

      def raise_psql_missing_error
        raise Error::Fail, 'The psql command not found.'\
                ' Make sure system has psql utility installed.'
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

      def raise_service_error
        raise Error::Fail, 'Please check whether database service is up & running state.'
      end
    end
  end
end
