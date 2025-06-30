module ForemanMaintain::Utils
  module Service
    class Systemd < Abstract
      attr_reader :instance_parent_unit

      def initialize(name, priority, options = {})
        super
        @sys = SystemHelpers.new
        @instance_parent_unit = options.fetch(:instance_parent_unit, nil)
      end

      def command(action)
        all = @options.fetch(:all, false)
        skip_enablement = @options.fetch(:skip_enablement, false)
        if skip_enablement && %w[enable disable].include?(action)
          return skip_enablement_message(action, @name)
        end

        cmd = "systemctl #{action} #{@name}"
        cmd += ' --all' if all
        cmd
      end

      def status
        execute('status')
      end

      def start
        execute('start')
      end

      def stop
        execute('stop')
      end

      def restart
        execute('restart')
      end

      def enable
        execute('enable')
      end

      def disable
        execute('disable')
      end

      def running?
        status.first == 0
      end

      def exist?
        ['enabled', 'disabled', 'generated'].include?(service_enabled_status)
      end

      def enabled?
        if @sys.systemd_installed?
          ['enabled', 'generated'].include?(service_enabled_status)
        end
      end

      def matches?(service)
        if service.is_a? String
          service == @name || File.fnmatch(service, @name)
        else
          super
        end
      end

      private

      def execute(action)
        @sys.execute_with_status(command(action))
      end

      def service_enabled_status
        @sys.execute("systemctl is-enabled #{@name} 2>&1 | tail -1").strip
      end

      def skip_enablement_message(action, name)
        # Enable and disable does not work well with globs since they treat them literally.
        # We are skipping the pulpcore-workers@* for these actions until they are configured in
        # a more managable way with systemd
        msg =
          "
\nWARNING: Skipping #{action} for #{name} as there are a variable amount of services to manage
and this command will not respond to glob operators. These services have been configured by
the installer and it is recommended to keep them enabled to prevent misconfiguration.\n
"
        puts msg
      end
    end
  end
end
