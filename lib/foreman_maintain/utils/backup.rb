require 'zlib'
require 'rubygems/package'
require 'yaml'

module ForemanMaintain
  module Utils
    class Backup
      include Concerns::SystemHelpers

      attr_accessor :standard_files, :katello_online_files,
        :foreman_online_files, :fpc_online_files

      ONLINE_BACKUP = 'online'.freeze
      OFFLINE_BACKUP = 'offline'.freeze

      def initialize(backup_dir)
        # fpc stands for foreman proxy w/ content
        @backup_dir = backup_dir
        @standard_files = ['config_files.tar.gz']
        @foreman_online_files = ['foreman.dump']
        @katello_online_files = @foreman_online_files + ['candlepin.dump', 'pulpcore.dump']
        @fpc_online_files = ['pulpcore.dump', 'container_gateway.dump']
      end

      def file_map
        @file_map ||= {
          :pulp_data => map_file(@backup_dir, 'pulp_data.tar'),
          :foreman_dump => map_file(@backup_dir, 'foreman.dump'),
          :iop_advisor_dump => map_file(@backup_dir, 'iop_advisor.dump'),
          :iop_inventory_dump => map_file(@backup_dir, 'iop_inventory.dump'),
          :iop_remediations_dump => map_file(@backup_dir, 'iop_remediations.dump'),
          :iop_vmaas_dump => map_file(@backup_dir, 'iop_vmaas.dump'),
          :iop_vulnerability_dump => map_file(@backup_dir, 'iop_vulnerability.dump'),
          :candlepin_dump => map_file(@backup_dir, 'candlepin.dump'),
          :config_files => map_file(@backup_dir, 'config_files.tar.gz'),
          :metadata => map_file(@backup_dir, 'metadata.yml'),
          :pulpcore_dump => map_file(@backup_dir, 'pulpcore.dump'),
          :container_gateway_dump => map_file(@backup_dir, 'container_gateway.dump'),
        }
      end

      def map_file(backup_dir, filename)
        file_path = File.join(backup_dir, filename)
        present = File.exist?(file_path)
        {
          :present => present,
          :path => file_path,
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
        fpc_online_backup?
      end

      def valid_katello_backup?
        katello_online_backup?
      end

      def valid_foreman_backup?
        foreman_online_backup?
      end

      def check_file_existence(existence_map)
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

      def katello_online_backup?
        present = [:candlepin_dump, :foreman_dump, :pulpcore_dump]
        absent = [:container_gateway_dump]
        check_file_existence(:present => present,
          :absent => absent)
      end

      def fpc_online_backup?
        present = [:pulpcore_dump, :container_gateway_dump]
        absent = [:candlepin_dump, :foreman_dump]
        check_file_existence(:present => present, :absent => absent)
      end

      def foreman_online_backup?
        check_file_existence(:present => [:foreman_dump],
          :absent => [:candlepin_dump, :pulpcore_dump, :container_gateway_dump])
      end

      def validate_hostname?
        # make sure that the system hostname is the same as the backup
        metadata.fetch('hostname', nil) == hostname
      end

      def validate_interfaces
        # I wanted to do `Socket.getifaddrs.map(&:name).uniq`,
        # but this has to work with Ruby 2.0, and Socket.getifaddrs is 2.1+
        errors = {}
        system_interfaces = Dir.entries('/sys/class/net') - ['.', '..']

        proxy_config = metadata.fetch('proxy_config', {})

        %w[dns dhcp].each do |feature|
          next unless proxy_config.fetch(feature, false)

          wanted_interface = proxy_config.fetch("#{feature}_interface", 'lo')
          unless system_interfaces.include?(wanted_interface)
            errors[feature] = { 'configured' => wanted_interface, 'available' => system_interfaces }
          end
        end

        return errors
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
        file_map[:pulp_data][:present]
      end

      def sql_dump_files_exist?
        file_map[:foreman_dump][:present] ||
          file_map[:candlepin_dump][:present] ||
          file_map[:pulpcore_dump][:present] ||
          file_map[:container_gateway_dump][:present]
      end

      def sql_needs_dump_restore?
        sql_dump_files_exist?
      end

      def incremental?
        !!metadata.fetch('incremental', false)
      end

      def online_backup?
        !!metadata.fetch('online', false)
      end

      def installed_rpms
        metadata.fetch('rpms', metadata.fetch(:rpms, []))
      end

      def with_puppetserver?
        installed_rpms.any? { |rpm| rpm.start_with?('puppetserver-') }
      end

      def source_os_version
        metadata.fetch('os_version', 'unknown')
      end

      def different_source_os?
        source_os_version != "#{os_name} #{os_version}"
      end

      def backup_type
        online_backup? ? ONLINE_BACKUP : OFFLINE_BACKUP
      end
    end
  end
end
