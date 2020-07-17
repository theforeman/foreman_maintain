module ForemanMaintain
  module Features
    class ForemanServer < ForemanMaintain::Feature
      metadata do
        label :foreman_server
        confine do
          server?
        end
      end

      FOREMAN_RELEASE_PACKAGE = 'foreman-release'.freeze

      def services
        if execute?('systemctl is-enabled foreman')
          [system_service('foreman', 30, :socket => 'foreman')]
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
          '/var/www/html/pub/katello-*',
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

      def current_version
        @current_version ||= rpm_version('foreman')
      end

      def rake!(command)
        execute!("foreman-rake #{command}")
      end

      def repos_rpm(version)
        "https://yum.theforeman.org/releases/#{version}/el#{feature(:instance).os_major_release}"\
        "/x86_64/#{FOREMAN_RELEASE_PACKAGE}.rpm"
      end

      def update_repos(version)
        repos_rpm = repos_rpm(version, feature(:instance).os_major_release)
        package_manager.update_or_install(FOREMAN_RELEASE_PACKAGE, repos_rpm, :assumeyes => true)
        %w[foreman-release-scl centos-release-scl-rh].each do |package|
          package_manager.update(package, :assumeyes => true)
        end
      end
    end
  end
end
