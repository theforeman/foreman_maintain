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
        failure_message = check_custom_hiera
        fail! failure_message if failure_message
      end

      # rubocop:disable Metrics/MethodLength
      def check_custom_hiera
        hiera_file = feature(:installer) ? feature(:installer).custom_hiera_file : nil
        return unless hiera_file
        if File.exist?(hiera_file) && (config = YAML.load_file(hiera_file)) &&
           config.key?('postgresql::server::config_entries')
          if config['postgresql::server::config_entries'].nil?
            return <<-MESSAGE.strip_heredoc
            ERROR: 'postgresql::server::config_entries' cannot be null.
            Please remove it from following file and re-run the command.
            - #{hiera_file}
            MESSAGE
          elsif config['postgresql::server::config_entries'].key?('checkpoint_segments')
            return <<-MESSAGE.strip_heredoc
            ERROR: Tuning option 'checkpoint_segments' found.
            This option is no longer valid for PostgreSQL 9.5 and onwards.
            Please remove it from following file and re-run the command.
            - #{hiera_file}
            MESSAGE
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
