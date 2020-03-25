module ForemanMaintain
  module Features
    class ForemanServer < ForemanMaintain::Feature
      metadata do
        label :foreman_server
        confine do
          server?
        end
      end

      def services
        if foreman_service_installed?
          [system_service('foreman', 30)]
        else
          [system_service('httpd', 30)]
        end
      end

      def plugins
        list_cmd = "export RUBYOPT='-W0'; foreman-rake plugin:list| grep 'Foreman plugin: '"
        plugin_list = execute(list_cmd).lines
        plugin_list.map do |line|
          plugin = line.split
          "#{plugin[2].chop}-#{plugin[3].chop}"
        end
      end

      def config_files
        [
          '/etc/httpd',
          '/var/www/html/pub',
          '/etc/squid',
          '/etc/foreman',
          '/etc/selinux/targeted/contexts/files/file_contexts.subs',
          '/etc/sysconfig/foreman',
          '/usr/share/ruby/vendor_ruby/puppet/reports/foreman.rb',
          '/var/lib/foreman'
        ]
      end

      def config_files_to_exclude
        [
          '/var/lib/foreman/public'
        ]
      end

      def services_running?
        services.all?(&:running?)
      end

      private

      def foreman_service_installed?
        package_manager.installed?(['foreman-service']) && check_min_version('foreman', '2.1')
      end
    end
  end
end
