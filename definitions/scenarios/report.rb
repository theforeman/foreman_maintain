module ForemanMaintain::Scenarios
  module Report
    class Generate < ForemanMaintain::Scenario::FilteredScenario
      metadata do
        description 'Generate the usage report'
        tags :report
        label :generate_report
        manual_detection
      end
    end
  end
end
