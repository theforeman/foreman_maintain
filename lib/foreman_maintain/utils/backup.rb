require 'zlib'
require 'rubygems/package'
require 'yaml'

module ForemanMaintain
  module Utils
    class Backup
      include Concerns::SystemHelpers

      attr_accessor :standard_files, :katello_online_files, :katello_offline_files,
                    :foreman_online_files, :foreman_offline_files, :fpc_offline_files,
                    :fpc_online_files

      def initialize(backup_dir)
        # fpc stands for foreman proxy w/ content
        @backup_dir = backup_dir
        @standard_files = ['config_files.tar.gz']
        @katello_online_files = ['mongo_dump', 'candlepin.dump', 'foreman.dump']
        if feature(:pulpcore)
          @katello_online_files << 'pulpcore.dump'
        end
        @katello_offline_files = ['mongo_data.tar.gz', 'pgsql_data.tar.gz']
        @foreman_online_files = ['foreman.dump']
        @foreman_offline_files = ['pgsql_data.tar.gz']
        @fpc_online_files = ['mongo_dump']
        @fpc_offline_files = ['mongo_data.tar.gz']
      end

      def file_map
        @file_map ||= {
          :mongo_data => map_file(@backup_dir, 'mongo_data.tar.gz'),
          :pgsql_data => map_file(@backup_dir, 'pgsql_data.tar.gz'),
          :pulp_data => map_file(@backup_dir, 'pulp_data.tar'),
          :foreman_dump => map_file(@backup_dir, 'foreman.dump'),
          :candlepin_dump => map_file(@backup_dir, 'candlepin.dump'),
          :mongo_dump => map_file(@backup_dir, 'mongo_dump'),
          :config_files => map_file(@backup_dir, 'config_files.tar.gz'),
          :pg_globals => map_file(@backup_dir, 'pg_globals.dump'),
          :metadata => map_file(@backup_dir, 'metadata.yml')
        }
        if feature(:pulpcore)
          @file_map[:pulpcore_dump] = map_file(@backup_dir, 'pulpcore.dump')
        end
        @file_map
      end

      def map_file(backup_dir, filename)
        file_path = File.join(backup_dir, filename)
        present = File.exist?(file_path)
        {
          :present => present,
          :path => file_path
        }
      end

      def present_files
        present_files = file_map.select { |_k, v| v[:present] }
        present_files.values.map { |f| File.basename(f[:path]) }
      end

      def valid_backup?
        file_map[:config_files][:present] && check_backup
      end

      def check_backup
        if feature(:instance).foreman_proxy_with_content?
          valid_fpc_backup?
        elsif feature(:katello)
          valid_katello_backup?
        else
          valid_foreman_backup?
        end
      end

      def valid_fpc_backup?
        fpc_online_backup? || fpc_standard_backup? || fpc_logical_backup?
      end

      def valid_katello_backup?
        katello_online_backup? || katello_standard_backup? || katello_logical_backup?
      end

      def valid_foreman_backup?
        foreman_standard_backup? || foreman_online_backup? || foreman_logical_backup?
      end

      def check_file_existence(existence_map)
        unless feature(:pulpcore)
          existence_map[:present].delete(:pulpcore_dump)
          existence_map[:absent].delete(:pulpcore_dump)
        end

        existence_map[:present].each do |file|
          unless file_map[file][:present]
            return false
          end
        end

        existence_map[:absent].each do |file|
          if file_map[file][:present]
            return false
          end
        end

        true
      end

      # TODO: Need to check for pulpcore feature?
      def katello_standard_backup?
        check_file_existence(:present => [:mongo_data, :pgsql_data],
                             :absent => [:candlepin_dump, :foreman_dump,
                                         :pulpcore_dump, :mongo_dump])
      end

      def katello_online_backup?
        check_file_existence(:present => [:candlepin_dump, :foreman_dump,
                                          :pulpcore_dump, :mongo_dump],
                             :absent => [:mongo_data, :pgsql_data])
      end

      def katello_logical_backup?
        check_file_existence(:present => [:mongo_dump, :mongo_data, :pgsql_data,
                                          :candlepin_dump, :pulpcore_dump, :foreman_dump],
                             :absent => [])
      end

      def fpc_standard_backup?
        check_file_existence(:present => [:mongo_data],
                             :absent => [:pgsql_data, :candlepin_dump,
                                         :foreman_dump, :mongo_dump, :pulpcore_dump])
      end

      def fpc_online_backup?
        absent = [:mongo_data, :pgsql_data, :candlepin_dump, :foreman_dump]

        check_file_existence(:present => [:mongo_dump], :absent => absent) ||
          check_file_existence(:present => [:pulpcore_dump], :absent => absent)
      end

      def fpc_logical_backup?
        absent = [:pgsql_data, :candlepin_dump, :foreman_dump]
        check_file_existence(:present => [:mongo_dump, :mongo_data], :absent => absent) ||
          check_file_existence(:present => [:pulpcore_dump], :absent => absent)
      end

      def foreman_standard_backup?
        check_file_existence(:present => [:pgsql_data],
                             :absent => [:candlepin_dump, :foreman_dump, :pulpcore_dump,
                                         :mongo_data, :mongo_dump])
      end

      def foreman_online_backup?
        check_file_existence(:present => [:foreman_dump],
                             :absent => [:candlepin_dump, :pgsql_data,
                                         :mongo_data, :mongo_dump])
      end

      def foreman_logical_backup?
        check_file_existence(:present => [:pgsql_data, :foreman_dump],
                             :absent => [:candlepin_dump, :mongo_data, :mongo_dump])
      end

      def validate_hostname?
        # make sure that the system hostname is the same as the backup
        config_tarball = file_map[:config_files][:path]
        tar_cmd = "tar zxf #{config_tarball} etc/httpd/conf/httpd.conf --to-stdout"
        status, httpd_config = execute_with_status(tar_cmd)

        # Incremental backups sometimes don't include httpd.conf. Since a "base" backup
        # is restored before an incremental, we can assume that the hostname is checked
        # during the base backup restore
        if status == 0
          match = httpd_config.match(/\s*ServerName\s+"*([^ "]+)"*\s*$/)
          match ? match[1] == hostname : false
        else
          true
        end
      end

      def metadata
        if file_map[:metadata][:present]
          YAML.load_file(file_map[:metadata][:path])
        else
          {}
        end
      end

      def pulp_tar_split?
        File.exist?(File.join(@backup_dir, 'pulp_data.part0002'))
      end

      def tar_backups_exist?
        file_map[:mongo_data][:present] ||
          file_map[:pulp_data][:present] ||
          file_map[:pgsql_data][:present]
      end

      def sql_dump_files_exist?
        file_map[:foreman_dump][:present] ||
          file_map[:candlepin_dump][:present] ||
          (feature(:pulpcore) && file_map[:pulpcore_dump][:present])
      end

      def incremental?
        !!metadata.fetch('incremental', false)
      end

      def online_backup?
        !!metadata.fetch('online', false)
      end
    end
  end
end
