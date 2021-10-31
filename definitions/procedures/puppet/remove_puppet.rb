module Procedures::Puppet
  class RemovePuppet < ForemanMaintain::Procedure
    metadata do
      description 'Remove Puppet feature'
      confine do
        feature(:puppet_server) &&
          (check_min_version('foreman', '3.0') || check_min_version('foreman-proxy', '3.0'))
      end
      advanced_run false
    end

    def run
      services = feature(:foreman_server).services + feature(:dynflow_sidekiq).services
      Procedures::Service::Stop.new(:only => services)
      execute!('foreman-rake db:migrate VERSION=0 SCOPE=foreman_puppet') if server_with_puppet?
      feature(:installer).run(installer_arguments_disabling_puppet.join(' '), :interactive => false)
      packages_action(:remove, packages_to_remove, :assumeyes => true)
    end

    private

    def server_with_puppet?
      find_package(foreman_plugin_name('foreman_puppet'))
    end

    def installer_arguments_disabling_puppet
      answers = feature(:installer).answers

      options = []
      options << '--no-enable-puppet' if answers.key?('puppet')
      options << '--no-enable-foreman-plugin-puppet' if answers['foreman::plugin::puppet']
      options << '--no-enable-foreman-cli-puppet' if answers['foreman::cli::puppet']
      if answers['foreman_proxy']
        options << '--foreman-proxy-puppet false'
        options << '--foreman-proxy-puppetca false'
      end
      options << '--foreman-proxy-content-puppet false' if answers.key?('foreman_proxy_content')
      options
    end

    def packages_to_remove
      packages = ['puppetserver']
      if server_with_puppet?
        packages << foreman_plugin_name('foreman_puppet')
        packages << hammer_plugin_name('foreman_puppet')
      end
      packages
    end
  end
end
