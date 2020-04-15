module ForemanMaintain::Scenarios
  class Backup < ForemanMaintain::Scenario
    metadata do
      description 'Backup'
      manual_detection
      tags :backup
      run_strategy :fail_fast
      param :strategy, 'Backup strategy. One of [:online, :offline, :snapshot]',
            :required => true
      param :backup_dir, 'Directory where to backup to', :required => true
      param :mount_dir, 'Snapshot mount directory'
      param :include_db_dumps, 'Include dumps of local dbs as part of offline'
      param :preserve_dir, 'Directory where to backup to'
      param :incremental_dir, 'Changes since specified backup only'
      param :proxy_features, 'List of proxy features to backup (default: all)', :array => true
      param :snapshot_mount_dir, 'Snapshot mount directory'
      param :snapshot_block_size, 'Snapshot block size'
      param :skip_pulp_content, 'Skip Pulp content during backup'
      param :tar_volume_size, 'Size of tar volume (indicates splitting)'
    end

    def compose
      check_valid_startegy
      safety_confirmation
      accessibility_confirmation
      prepare_directory
      logical_volume_confirmation
      add_step_with_context(Procedures::Backup::Metadata)

      case strategy
      when :online
        add_online_backup_steps
      when :offline
        add_offline_backup_steps
      when :snapshot
        add_snapshot_backup_steps
      end
      add_step_with_context(Procedures::Backup::CompressData)
    end

    # rubocop:disable  Metrics/MethodLength
    def set_context_mapping
      context.map(:backup_dir,
                  Checks::Backup::DirectoryReady => :backup_dir,
                  Procedures::Backup::PrepareDirectory => :backup_dir,
                  Procedures::Backup::Metadata => :backup_dir,
                  Procedures::Backup::ConfigFiles => :backup_dir,
                  Procedures::Backup::CompressData => :backup_dir,
                  Procedures::Backup::Pulp => :backup_dir,
                  Procedures::Backup::Online::Mongo => :backup_dir,
                  Procedures::Backup::Online::PgGlobalObjects => :backup_dir,
                  Procedures::Backup::Online::CandlepinDB => :backup_dir,
                  Procedures::Backup::Online::ForemanDB => :backup_dir,
                  Procedures::Backup::Online::PulpcoreDB => :backup_dir,
                  Procedures::Backup::Offline::CandlepinDB => :backup_dir,
                  Procedures::Backup::Offline::ForemanDB => :backup_dir,
                  Procedures::Backup::Offline::PulpcoreDB => :backup_dir,
                  Procedures::Backup::Offline::Mongo => :backup_dir,
                  Procedures::Backup::Snapshot::LogicalVolumeConfirmation => :backup_dir,
                  Procedures::Backup::Snapshot::MountCandlepinDB => :backup_dir,
                  Procedures::Backup::Snapshot::MountForemanDB => :backup_dir,
                  Procedures::Backup::Snapshot::MountPulpcoreDB => :backup_dir,
                  Procedures::Backup::Snapshot::MountMongo => :backup_dir)
      context.map(:preserve_dir,
                  Checks::Backup::DirectoryReady => :preserve_dir,
                  Procedures::Backup::PrepareDirectory => :preserve_dir)
      context.map(:incremental_dir,
                  Procedures::Backup::PrepareDirectory => :incremental_dir,
                  Procedures::Backup::Metadata => :incremental_dir)
      context.map(:proxy_features,
                  Procedures::Backup::ConfigFiles => :proxy_features)
      context.map(:snapshot_mount_dir,
                  Procedures::Backup::Snapshot::PrepareMount => :mount_dir,
                  Procedures::Backup::Snapshot::MountMongo => :mount_dir,
                  Procedures::Backup::Snapshot::MountPulp => :mount_dir,
                  Procedures::Backup::Snapshot::CleanMount => :mount_dir,
                  Procedures::Backup::Snapshot::MountCandlepinDB => :mount_dir,
                  Procedures::Backup::Snapshot::MountForemanDB => :mount_dir,
                  Procedures::Backup::Snapshot::MountPulpcoreDB => :mount_dir,
                  Procedures::Backup::Offline::Mongo => :mount_dir,
                  Procedures::Backup::Pulp => :mount_dir,
                  Procedures::Backup::Offline::CandlepinDB => :mount_dir,
                  Procedures::Backup::Offline::ForemanDB => :mount_dir,
                  Procedures::Backup::Offline::PulpcoreDB => :mount_dir)
      context.map(:snapshot_block_size,
                  Procedures::Backup::Snapshot::MountMongo => :block_size,
                  Procedures::Backup::Snapshot::MountPulp => :block_size,
                  Procedures::Backup::Snapshot::MountForemanDB => :block_size,
                  Procedures::Backup::Snapshot::MountCandlepinDB => :block_size,
                  Procedures::Backup::Snapshot::MountPulpcoreDB => :block_size)
      context.map(:skip_pulp_content,
                  Procedures::Backup::Pulp => :skip,
                  Procedures::Backup::Snapshot::LogicalVolumeConfirmation => :skip_pulp,
                  Procedures::Backup::Snapshot::MountPulp => :skip)
      context.map(:tar_volume_size,
                  Procedures::Backup::Pulp => :tar_volume_size)
    end
    # rubocop:enable  Metrics/MethodLength

    private

    def prepare_directory
      add_steps_with_context(
        Procedures::Backup::PrepareDirectory,
        Checks::Backup::DirectoryReady
      )
    end

    def logical_volume_confirmation
      if strategy == :snapshot
        add_step_with_context(Procedures::Backup::Snapshot::LogicalVolumeConfirmation)
      end
    end

    def accessibility_confirmation
      if [:offline, :snapshot].include?(strategy)
        add_step_with_context(Procedures::Backup::AccessibilityConfirmation)
      end
    end

    def safety_confirmation
      if online_backup? || include_db_dumps?
        add_step_with_context(Procedures::Backup::Online::SafetyConfirmation)
      end
    end

    def check_valid_startegy
      unless [:online, :offline, :snapshot].include? strategy
        raise ArgumentError, "Unsupported strategy '#{strategy}'"
      end
    end

    def add_offline_backup_steps
      include_dumps if include_db_dumps?
      add_step_with_context(Procedures::ForemanProxy::Features, :load_only => true)
      add_steps_with_context(
        find_procedures(:maintenance_mode_on),
        Procedures::Service::Stop,
        Procedures::Backup::ConfigFiles,
        Procedures::Backup::Pulp,
        Procedures::Backup::Offline::Mongo,
        Procedures::Backup::Offline::CandlepinDB,
        Procedures::Backup::Offline::ForemanDB,
        Procedures::Backup::Offline::PulpcoreDB,
        Procedures::Service::Start,
        find_procedures(:maintenance_mode_off)
      )
    end

    def include_dumps
      if feature(:instance).postgresql_local?
        add_step_with_context(Procedures::Backup::Online::PgGlobalObjects)
      end
      if feature(:instance).database_local?(:candlepin_database)
        add_step_with_context(Procedures::Backup::Online::CandlepinDB)
      end
      if feature(:instance).database_local?(:foreman_database)
        add_step_with_context(Procedures::Backup::Online::ForemanDB)
      end
      if feature(:instance).database_local?(:pulpcore_database)
        add_step_with_context(Procedures::Backup::Online::PulpcoreDB)
      end
      if feature(:instance).database_local?(:mongo)
        add_step_with_context(Procedures::Backup::Online::Mongo)
      end
    end

    # rubocop:disable  Metrics/MethodLength
    def add_snapshot_backup_steps
      include_dumps if include_db_dumps?
      add_step_with_context(Procedures::ForemanProxy::Features, :load_only => true)
      add_steps_with_context(
        Procedures::Backup::Snapshot::PrepareMount,
        find_procedures(:maintenance_mode_on),
        Procedures::Service::Stop,
        Procedures::Backup::ConfigFiles,
        Procedures::Backup::Snapshot::MountMongo,
        Procedures::Backup::Snapshot::MountPulp,
        Procedures::Backup::Snapshot::MountCandlepinDB,
        Procedures::Backup::Snapshot::MountForemanDB,
        Procedures::Backup::Snapshot::MountPulpcoreDB,
        Procedures::Service::Start,
        find_procedures(:maintenance_mode_off),
        Procedures::Backup::Pulp
      )
      if feature(:instance).database_local?(:candlepin_database)
        add_step_with_context(Procedures::Backup::Offline::CandlepinDB)
      end
      if feature(:instance).database_local?(:foreman_database)
        add_step_with_context(Procedures::Backup::Offline::ForemanDB)
      end
      if feature(:instance).database_local?(:pulpcore_database)
        add_step_with_context(Procedures::Backup::Offline::PulpcoreDB)
      end
      if feature(:instance).database_local?(:mongo)
        add_step_with_context(Procedures::Backup::Offline::Mongo)
      end
      add_step_with_context(Procedures::Backup::Snapshot::CleanMount)
    end
    # rubocop:enable  Metrics/MethodLength

    def add_online_backup_steps
      add_step_with_context(Procedures::Backup::ConfigFiles, :ignore_changed_files => true,
                                                             :online_backup => true)
      add_step_with_context(Procedures::Backup::Pulp, :ensure_unchanged => true)
      add_steps_with_context(
        Procedures::Backup::Online::Mongo,
        Procedures::Backup::Online::PgGlobalObjects,
        Procedures::Backup::Online::CandlepinDB,
        Procedures::Backup::Online::ForemanDB,
        Procedures::Backup::Online::PulpcoreDB
      )
      add_step_with_context(Procedures::Backup::Metadata, :online_backup => true)
    end

    def strategy
      context.get(:strategy)
    end

    def include_db_dumps?
      !!context.get(:include_db_dumps)
    end

    def online_backup?
      strategy == :online
    end
  end

  class BackupRescueCleanup < ForemanMaintain::Scenario
    metadata do
      description 'Failed backup cleanup'
      manual_detection
      run_strategy :fail_slow
      tags :backup
      param :backup_dir, 'Directory where to backup to', :required => true
      param :mount_dir, 'Snapshot mount directory'
      param :preserve_dir, 'Directory where to backup to'
    end

    def compose
      add_step_with_context(Procedures::Service::Start) if strategy != :online
      add_steps_with_context(find_procedures(:maintenance_mode_off)) if strategy != :online
      add_step_with_context(Procedures::Backup::Snapshot::CleanMount) if strategy == :snapshot
      add_step_with_context(Procedures::Backup::Clean)
    end

    def set_context_mapping
      context.map(:snapshot_mount_dir,
                  Procedures::Backup::Snapshot::CleanMount => :mount_dir)
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
