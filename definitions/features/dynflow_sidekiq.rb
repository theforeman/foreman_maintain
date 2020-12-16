class Features::DynflowSidekiq < ForemanMaintain::Feature
  metadata do
    label :dynflow_sidekiq

    confine do
      server? && find_package('foreman-dynflow-sidekiq')
    end
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

  def services
    [
      system_service('dynflow-sidekiq@orchestrator', 30, :parent_unit => 'dynflow-sidekiq@'),
      system_service('dynflow-sidekiq@worker-hosts-queue', 31, :parent_unit => 'dynflow-sidekiq@'),
      system_service('dynflow-sidekiq@worker', 31, :parent_unit => 'dynflow-sidekiq@')
    ]
  end
end
