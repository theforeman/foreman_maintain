module ForemanMaintain::Utils
  module Service
    class Systemd < Abstract
      def initialize(name, priority, options = {})
        super
        @sys = SystemHelpers.new
      end

      def command(action, options = {})
        do_wait = options.fetch(:wait, true) # wait for service to start
        all = @options.fetch(:all, false)
        skip_enablement = @options.fetch(:skip_enablement, false)

        if skip_enablement && %w[enable disable].include?(action)
          return skip_enablement_message(action, @name)
        end

        if do_wait && File.exist?('/usr/sbin/service-wait')
          "service-wait #{@name} #{action}"
        else
          cmd = "systemctl #{action} #{@name}"
          cmd += ' --all' if all
          cmd
        end
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

      def enable
        execute('enable', :wait => false)
      end

      def disable
        execute('disable', :wait => false)
      end

      def running?
        status.first == 0
      end

      def exist?
        if @sys.systemd_installed?
          systemd = service_enabled_status
          systemd == 'enabled' || systemd == 'disabled'
        else
          File.exist?("/etc/init.d/#{@name}")
        end
      end

      def enabled?
        if @sys.systemd_installed?
          service_enabled_status == 'enabled'
        end
      end

      private

      def execute(action, options = {})
        @sys.execute_with_status(command(action, options))
      end

      def service_enabled_status
        @sys.execute("systemctl is-enabled #{@name} 2>&1 | tail -1").strip
      end

      def skip_enablement_message(action, name)
        # Enable and disable does not work well with globs since they treat them literally.
        # We are skipping the pulpcore-workers@* for these actions until they are configured in
        # a more managable way with systemd
        # rubocop:disable Layout/IndentAssignment
        msg =
"
\nWARNING: Skipping #{action} for #{name} as there are a variable amount of services to manage
and this command will not respond to glob operators. These services have been configured by
the installer and it is recommended to keep them enabled to prevent misconfiguration.\n
"
        # rubocop:enable Layout/IndentAssignment
        puts msg
      end
    end
  end
end
