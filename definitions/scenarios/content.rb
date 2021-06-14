module ForemanMaintain::Scenarios
  module Content
    class ContentBase < ForemanMaintain::Scenario
      def enable_and_start_services
        add_step(Procedures::Service::Start)
        add_step(Procedures::Service::Enable.
                 new(:only => Features::Pulpcore.pulpcore_migration_services))
        add_step(Procedures::Service::Start.
                 new(:only => Features::Pulpcore.pulpcore_migration_services))
      end

      def disable_and_stop_services
        add_step(Procedures::Service::Stop.
                 new(:only => Features::Pulpcore.pulpcore_migration_services))
        add_step(Procedures::Service::Disable.
                 new(:only => Features::Pulpcore.pulpcore_migration_services))
      end
    end

    class Prepare < ContentBase
      metadata do
        label :content_prepare
        description 'Prepare content for Pulp 3'
        manual_detection
      end

      def compose
        if feature(:satellite) && feature(:satellite).at_least_version?('6.9')
          enable_and_start_services
          add_step(Procedures::Content::Prepare)
          disable_and_stop_services
        elsif !feature(:satellite)
          add_step(Procedures::Content::Prepare)
        end
      end
    end

    class Switchover < ContentBase
      metadata do
        label :content_switchover
        description 'Switch support for certain content from Pulp 2 to Pulp 3'
        manual_detection
      end

      def compose
        # FIXME: remove this condition for the 6.10 upgrade scenario
        if Procedures::Content::Switchover.present?
          add_step(Procedures::Content::Switchover)
          add_step(Procedures::Foreman::ApipieCache)
        end
      end
    end

    class PrepareAbort < ContentBase
      metadata do
        label :content_prepare_abort
        description 'Abort all running Pulp 2 to Pulp 3 migration tasks'
        manual_detection
      end

      def compose
        if !feature(:satellite) || feature(:satellite).at_least_version?('6.9')
          add_step(Procedures::Content::PrepareAbort)
        end
      end
    end

    class MigrationStats < ContentBase
      metadata do
        label :content_migration_stats
        description 'Retrieve Pulp 2 to Pulp 3 migration statistics'
        manual_detection
      end

      def compose
        if !feature(:satellite) || feature(:satellite).at_least_version?('6.9')
          add_step(Procedures::Content::MigrationStats)
        end
      end
    end

    class MigrationReset < ContentBase
      metadata do
        label :content_migration_reset
        description 'Reset the Pulp 2 to Pulp 3 migration data (pre-switchover)'
        manual_detection
      end

      def compose
        if feature(:satellite) && feature(:satellite).at_least_version?('6.9')
          enable_and_start_services
          add_step(Procedures::Content::MigrationReset)
          disable_and_stop_services
        elsif !feature(:satellite)
          add_step(Procedures::Content::MigrationReset)
        end
      end
    end

    class RemovePulp2 < ContentBase
      metadata do
        label :content_remove_pulp2
        description 'Remove Pulp2 and mongodb packages and data'
        param :assumeyes, 'Do not ask for confirmation'
        manual_detection
      end

      def set_context_mapping
        context.map(:assumeyes, Procedures::Pulp::Remove => :assumeyes)
      end

      def compose
        add_step_with_context(Procedures::Pulp::Remove)
      end
    end
  end
end
