module ForemanMaintain::Scenarios
  module Content
    class Prepare < ForemanMaintain::Scenario
      metadata do
        label :content_prepare
        description 'Prepare content for Pulp 3'
        manual_detection
      end

      def compose
        add_step(Procedures::Content::Prepare)
      end
    end

    class Switchover < ForemanMaintain::Scenario
      metadata do
        label :content_switchover
        description 'Switch support for certain content from Pulp 2 to Pulp 3'
        manual_detection
      end

      def compose
        add_step(Procedures::Content::Switchover)
      end
    end
  end
end
