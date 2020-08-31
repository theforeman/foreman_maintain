module Checks
  module Foreman
    class CheckpointSegments < ForemanMaintain::Check
      metadata do
        label :check_checkpoint_segments
        description 'Check if checkpoint_segments parameter persent in custom hiera'
      end

      def run
        files = []
        files << check_postgres_config
        files << check_custom_hiera
        # Make sure array does not contain nil value
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
        if File.exist?(hiera_file)
          config = YAML.load(File.read(hiera_file))
          if !config.nil? && config.key?('postgresql::server::config_entries') &&
             !config['postgresql::server::config_entries'].nil? &&
             config['postgresql::server::config_entries'].key?('checkpoint_segments')
            return hiera_file
          end
        end
      end

      def check_postgres_config
        param = /(?<!#)checkpoint_segments/
        config_file = postgres_config_files
        if File.exist?(config_file)
          file = File.read(config_file)
          return config_file if file.match(param)
        end
      end

      def postgres_config_files
        if find_package('postgresql-server')
          '/var/lib/pgsql/data/postgresql.conf'
        else
          '/var/opt/rh/rh-postgresql12/lib/pgsql/data/postgresql.conf'
        end
      end
    end
  end
end
