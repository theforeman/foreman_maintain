module Checks
  module Foreman
    class CheckpointSegments < ForemanMaintain::Check
      metadata do
        label :check_postgresql_checkpoint_segments
        description 'Check if checkpoint_segments configuration exists on the system'
        confine do
          feature(:foreman)
        end
      end

      def run
        files = []
        files << check_postgres_config
        files << check_custom_hiera
        unless files.compact.empty?
          failure_message = <<-MESSAGE.strip_heredoc
          ERROR: Tuning option 'checkpoint_segments' found.
          This option is no longer valid for PostgreSQL 9.5 and onwards.
          Please remove it from following files and re-run the command.
          #{files.join("\n")}
          MESSAGE
          fail! failure_message
        end
      end

      def check_custom_hiera
        hiera_file = feature(:installer) ? feature(:installer).custom_hiera_file : nil
        return unless hiera_file
        if File.exist?(hiera_file) && (config = YAML.load_file(hiera_file)) &&
           config.key?('postgresql::server::config_entries')
          if !config['postgresql::server::config_entries'].nil? &&
             config['postgresql::server::config_entries'].key?('checkpoint_segments')
            return hiera_file
          end
        end
      end

      def check_postgres_config
        param = /(?<!#)checkpoint_segments/
        config_file = postgresql_config_file
        if File.exist?(config_file) && (config = File.read(config_file))
          return config_file if config.match(param)
        end
      end

      def postgresql_config_file
        if find_package('postgresql-server')
          '/var/lib/pgsql/data/postgresql.conf'
        else
          '/var/opt/rh/rh-postgresql12/lib/pgsql/data/postgresql.conf'
        end
      end
    end
  end
end
