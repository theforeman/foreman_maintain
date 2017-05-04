module ForemanMaintain
  module Utils
    class Hammer
      class CredentialsError < RuntimeError
      end
      include Concerns::SystemHelpers

      attr_reader :settings

      def self.instance
        @instance ||= new
      end

      def config_file
        config_dir = File.dirname(ForemanMaintain.config_file)
        File.join(config_dir, 'foreman-maintain-hammer.yml')
      end

      # tries to setup hammer based on default configuration and returns true
      # if it succeeds
      def setup_from_default
        default_config_file = File.expand_path('~/.hammer/cli.modules.d/foreman.yml')
        return unless File.exist?(default_config_file)
        hammer_config = YAML.load_file(default_config_file)
        foreman_config = hammer_config.fetch(:foreman, {})
        if !foreman_config[:username].to_s.empty? && !foreman_config[:password].to_s.empty?
          save_config(hammer_config)
          ready? && default_config_file
        end
      end

      def setup_from_answers(username = nil, password = nil)
        save_config(:foreman => { :username => username, :password => password })
        ready?
      end

      # Run a hammer command, examples:
      # run_command('host list')
      def run_command(args)
        output = execute("#{command_base} #{args}")
        if output =~ /Invalid username or password/
          raise CredentialsError, 'Invalid hammer credentials: '\
            'we expect the hammer username/password to be stored'\
            "in #{config_file}"
        end
        output
      end

      def configured?
        File.exist?(config_file)
      end

      def ready?
        return @ready if defined? @ready
        return false unless configured?
        run_command('architecture list')
        @ready = true
      rescue CredentialsError
        @ready = false
      end

      private

      def command_base
        %(LANG=en_US.utf-8 hammer -c "#{config_file}" --interactive=no)
      end

      def save_config(config)
        remove_instance_variable '@ready' if defined? @ready
        File.open(config_file, 'w', 0o600) { |f| f.puts YAML.dump(config) }
      end
    end
  end
end
