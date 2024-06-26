module ForemanMaintain::Scenarios
  class Backup < ForemanMaintain::Scenario
    metadata do
      description 'Backup'
      manual_detection
      tags :backup
      run_strategy :fail_fast
      param :strategy, 'Backup strategy. One of [:online, :offline]',
        :required => true
      param :backup_dir, 'Directory where to backup to', :required => true
      param :preserve_dir, 'Directory where to backup to'
      param :incremental_dir, 'Changes since specified backup only'
      param :proxy_features, 'List of proxy features to backup (default: all)', :array => true
      param :skip_pulp_content, 'Skip Pulp content during backup'
      param :tar_volume_size, 'Size of tar volume (indicates splitting)'
    end

    def compose
      check_valid_strategy
      add_step_with_context(Checks::Backup::IncrementalParentType,
        :online_backup => strategy == :online)
      safety_confirmation
      add_step_with_context(Procedures::Backup::AccessibilityConfirmation) if strategy == :offline
      add_step_with_context(Procedures::Backup::PrepareDirectory,
        :online_backup => strategy == :online)
      add_step_with_context(Procedures::Backup::Metadata, :online_backup => strategy == :online)

      case strategy
      when :online
        add_online_backup_steps
      when :offline
        add_offline_backup_steps
      end

      add_step_with_context(Procedures::Backup::CompressData)
    end

    # rubocop:disable  Metrics/MethodLength
    def set_context_mapping
      context.map(:backup_dir,
        Procedures::Backup::PrepareDirectory => :backup_dir,
        Procedures::Backup::Metadata => :backup_dir,
        Procedures::Backup::ConfigFiles => :backup_dir,
        Procedures::Backup::CompressData => :backup_dir,
        Procedures::Backup::Pulp => :backup_dir,
        Procedures::Backup::Online::CandlepinDB => :backup_dir,
        Procedures::Backup::Online::ForemanDB => :backup_dir,
        Procedures::Backup::Online::PulpcoreDB => :backup_dir)
      context.map(:preserve_dir,
        Procedures::Backup::PrepareDirectory => :preserve_dir)
      context.map(:incremental_dir,
        Checks::Backup::IncrementalParentType => :incremental_dir,
        Procedures::Backup::PrepareDirectory => :incremental_dir,
        Procedures::Backup::Metadata => :incremental_dir)
      context.map(:proxy_features,
        Procedures::Backup::ConfigFiles => :proxy_features)
      context.map(:skip_pulp_content,
        Procedures::Backup::Pulp => :skip)
      context.map(:tar_volume_size,
        Procedures::Backup::Pulp => :tar_volume_size)
    end
    # rubocop:enable  Metrics/MethodLength

    private

    def safety_confirmation
      if strategy == :online
        add_step_with_context(Procedures::Backup::Online::SafetyConfirmation)
      end
    end

    def check_valid_strategy
      unless [:online, :offline].include? strategy
        raise ArgumentError, "Unsupported strategy '#{strategy}'"
      end
    end

    def add_offline_backup_steps
      add_step_with_context(Procedures::ForemanProxy::Features, :load_only => true)
      add_steps_with_context(
        Procedures::Service::Stop,
        Procedures::Backup::ConfigFiles,
        Procedures::Backup::Pulp
      )

      if feature(:instance).postgresql_local?
        add_step(Procedures::Service::Start.new(:only => ['postgresql']))
      end

      add_database_backup_steps

      add_steps_with_context(Procedures::Service::Start)
    end

    def add_online_backup_steps
      add_step_with_context(Procedures::Backup::ConfigFiles, :ignore_changed_files => true,
        :online_backup => true)
      add_step_with_context(Procedures::Backup::Pulp, :ensure_unchanged => true)
      add_database_backup_steps
    end

    def add_database_backup_steps
      add_steps_with_context(
        Procedures::Backup::Online::CandlepinDB,
        Procedures::Backup::Online::ForemanDB,
        Procedures::Backup::Online::PulpcoreDB
      )
    end

    def strategy
      context.get(:strategy)
    end
  end

  class BackupRescueCleanup < ForemanMaintain::Scenario
    metadata do
      description 'Failed backup cleanup'
      manual_detection
      run_strategy :fail_slow
      tags :backup
      param :backup_dir, 'Directory where to backup to', :required => true
      param :preserve_dir, 'Directory where to backup to'
    end

    def compose
      if strategy == :offline
        add_step_with_context(Procedures::Service::Start)
      end
      add_step_with_context(Procedures::Backup::Clean)
    end

    def set_context_mapping
      context.map(:backup_dir,
        Procedures::Backup::Clean => :backup_dir)
      context.map(:preserve_dir,
        Procedures::Backup::Clean => :preserve_dir)
    end

    private

    def strategy
      context.get(:strategy)
    end
  end
end
