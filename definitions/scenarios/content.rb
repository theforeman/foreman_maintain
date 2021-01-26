module ForemanMaintain::Scenarios
  module Content
    class Prepare < ForemanMaintain::Scenario
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
        end
      end

      private

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

    class Switchover < ForemanMaintain::Scenario
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

    class PrepareAbort < ForemanMaintain::Scenario
      metadata do
        label :content_prepare_abort
        description 'Abort all running Pulp 2 to Pulp 3 migration tasks'
        manual_detection
      end

      def compose
        if feature(:satellite) && feature(:satellite).at_least_version?('6.9')
          add_step(Procedures::Content::PrepareAbort)
        end
      end
    end

    class MigrationStats < ForemanMaintain::Scenario
      metadata do
        label :content_migration_stats
        description 'Retrieve Pulp 2 to Pulp 3 migration statistics'
        manual_detection
      end

      def compose
        if feature(:satellite) && feature(:satellite).at_least_version?('6.9')
          add_step(Procedures::Content::MigrationStats)
        end
      end
    end

    class RemovePulp2 < ForemanMaintain::Scenario
      metadata do
        label :content_remove_pulp2
        description 'Remove Pulp2 and mongodb packages and data'
        manual_detection
      end

      def compose
        add_step(Procedures::Pulp::Remove)
      end
    end
  end
end
