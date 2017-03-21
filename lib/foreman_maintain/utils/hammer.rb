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

      # Run a hammer command, examples:
      # run_command('host list')
      def run_command(args)
        output = execute("#{command_base} #{args}")
        if output =~ /Invalid username or password/
          # TODO: change the error message after we are able to ask the user
          # for credentials and store it somewhere
          raise CredentialsError, 'Invalid hammer credentials: '\
            'we expect the hammer username/password to be stored'\
            'in ~/.hammer/cli.modules.d/foreman.yml'
        end
        output
      end

      def ready?
        return @configured if defined? @configured
        run_command('architecture list')
        @ready = true
      rescue CredentialsError
        @ready = false
      end

      private

      def command_base
        'LANG=en_US.utf-8 hammer --interactive=no'
      end
    end
  end
end
