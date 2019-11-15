module ForemanMaintain::Utils
  module Service
    class Systemd < Abstract
      def initialize(name, priority, _options = {})
        super
        @sys = SystemHelpers.new
      end

      def command(action, options = {})
        do_wait = options.fetch(:wait, true) # wait for service to start
        all = options.fetch(:all, false)
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
          systemd = @sys.execute("systemctl is-enabled #{@name} 2>&1 | tail -1").strip
          systemd == 'enabled' || systemd == 'disabled'
        else
          File.exist?("/etc/init.d/#{@name}")
        end
      end

      private

      def execute(action, options = {})
        @sys.execute_with_status(command(action, options))
      end
    end
  end
end
