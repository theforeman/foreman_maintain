module Checks
  module Foreman
    class CheckpointSegments < ForemanMaintain::Check
      metadata do
        label :check_postgresql_checkpoint_segments
        description 'Check if checkpoint_segments configuration exists on the system'
        confine do
          feature(:foreman) && feature(:installer) &&
            File.exist?(feature(:installer).custom_hiera_file)
        end
      end

      def run
        failure_message = check_custom_hiera
        fail! failure_message if failure_message
      end

      # rubocop:disable Metrics/MethodLength
      def check_custom_hiera
        hiera_file = feature(:installer).custom_hiera_file
        if (config = YAML.load_file(hiera_file)) &&
           config.key?('postgresql::server::config_entries')
          if config['postgresql::server::config_entries'].nil?
            return <<-MESSAGE.strip_heredoc
            ERROR: 'postgresql::server::config_entries' cannot be null.
            Please remove it from following file and re-run the command.
            - #{hiera_file}
            MESSAGE
          elsif config['postgresql::server::config_entries'].key?('checkpoint_segments')
            message = <<-MESSAGE.strip_heredoc
            ERROR: Tuning option 'checkpoint_segments' found.
            This option is no longer valid for PostgreSQL 9.5 or newer.
            Please remove it from following file and re-run the command.
            - #{hiera_file}
            MESSAGE
            if feature(:katello)
              message += <<-MESSAGE.strip_heredoc
              The presence of checkpoint_segments in #{hiera_file} indicates manual tuning.
              Manual tuning can override values provided by the --tuning parameter.
              Review #{hiera_file} for values that are already provided by the built in tuning profiles.
              Built in tuning profiles also provide a supported upgrade path.
              MESSAGE
            end
            return message
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
