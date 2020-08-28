module Checks
  module Foreman
    class CheckpointSegments < ForemanMaintain::Check
      metadata do
        label :check_checkpoint_segments
        description 'Check if checkpoint_segments parameter persent in custom hiera'
        tags :pre_upgrade
      end

      HIERA_FILE = '/etc/foreman-installer/custom-hiera.yaml'.freeze

      def run
        files = []
        files << feature(:foreman_database).config_files[0] if check_postgres_config
        files << HIERA_FILE if check_custom_hiera
        unless files.empty?
          message = ERB.new(<<-BLOCK.strip_heredoc).result(binding)
          ERROR:
            checkpoint_segments tuning found.
            This tuning option is no longer valid in PostgreSQL 9.5+
            Please remove this from the following locations and then re-run the foreman-maintain upgrade check:
            <% files.each do |file| %>
              - <%= file %>
            <% end %>
          BLOCK
          fail! message
        end
      end

      def check_custom_hiera
        if File.exist?(HIERA_FILE)
          config = YAML.load(File.read(HIERA_FILE))
          if !config.nil? && config.key?('postgresql::server::config_entries') &&
             config['postgresql::server::config_entries'].key?('checkpoint_segments')
            return true
          end
        end
      end

      def check_postgres_config
        param = /(?<!#)checkpoint_segments/
        config_file = feature(:foreman_database).config_files[0]
        if File.exist?(config_file)
          file = File.read(config_file)
          return file.match(param)
        end
      end
    end
  end
end
