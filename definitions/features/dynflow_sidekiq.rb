class Features::DynflowSidekiq < ForemanMaintain::Feature
  metadata do
    label :dynflow_sidekiq

    confine do
      server? && find_package('foreman-dynflow-sidekiq')
    end

    def services
      [
        # TODO: Move redis to a separate feature when we're sure how it will be configured
        system_service('redis', 10),
        service_names.map { |service| system_service service, instance_priority(service) }
      ].flatten
    end

    def config_files
      [
        '/etc/foreman/dynflow',
        # Workaround until foreman-installer can deploy scaled workers
        configured_services.map { |service| "/etc/systemd/system/multi-user.target.wants/#{service}.service" }
      ].flatten
    end

    private

    def instance_priority(instance)
      # Orchestrator should be started before the workers are
      instance.end_with?('@orchestrator') ? 30 : 31
    end

    def service_names
      configured_instances.map { |instance| "dynflow-sidekiq@#{instance}" }
    end

    def configured_instances
      Dir["/etc/foreman/dynflow/*"].map { |config| File.basename(config).gsub(/\.yml$/, '') }
    end
  end
end
