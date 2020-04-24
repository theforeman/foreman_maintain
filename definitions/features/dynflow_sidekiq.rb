class Features::DynflowSidekiq < ForemanMaintain::Feature
  metadata do
    label :dynflow_sidekiq

    confine do
      server? && find_package('foreman-dynflow-sidekiq')
    end
  end

  def services
    service_names.map { |service| system_service service, instance_priority(service) }
  end

  def config_files
    # Workaround until foreman-installer can deploy scaled workers
    service_symlinks = configured_instances.map do |service|
      "/etc/systemd/system/multi-user.target.wants/#{service}.service"
    end
    [
      '/etc/foreman/dynflow',
      service_symlinks
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
    Dir['/etc/foreman/dynflow/*'].map { |config| File.basename(config, '.yml') }
  end
end
