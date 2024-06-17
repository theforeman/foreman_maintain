class Features::DynflowSidekiq < ForemanMaintain::Feature
  metadata do
    label :dynflow_sidekiq

    confine do
      server? && find_package('foreman-dynflow-sidekiq')
    end
  end

  def config_files
    [
      '/etc/foreman/dynflow',
    ]
  end

  def services
    service_names.map do |service|
      system_service service, instance_priority(service),
        :instance_parent_unit => 'dynflow-sidekiq@'
    end
  end

  def workers
    services.reject { |service| service.name.end_with?('@orchestrator') }
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
    Dir['/etc/foreman/dynflow/*.yml'].map { |config| File.basename(config, '.yml') }
  end
end
