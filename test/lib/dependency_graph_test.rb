require 'test_helper'

module ForemanMaintain
  describe DependencyGraph do
    let(:scenario) { Scenarios::PresentUpgrade::PreUpgradeChecks.new }

    let(:step_1) { Checks::ExternalServiceIsAccessible.new }
    let(:step_2) { Procedures::PresentServiceRestart.new }
    let(:step_3) { Procedures::PresentServiceStart.new }

    let(:steps) { [step_1, step_2, step_3] }


    it 'preserves the order the steps were added' do
      ordered_steps = DependencyGraph.sort(steps)
      ordered_steps.map(&:label).must_equal [:external_service_is_accessible, :present_service_restart, :present_service_start]
    end

    it 'should satisfy order requirements' do
      step_2.class.stubs(:before => [step_1.label])
      ordered_steps = DependencyGraph.sort(steps)
      ordered_steps.map(&:label).must_equal [:present_service_restart, :external_service_is_accessible, :present_service_start]
    end
  end
end
