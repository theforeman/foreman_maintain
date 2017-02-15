require 'test_helper'

module ForemanMaintain
  describe Detector do
    include ResetTestState

    let :detector do
      Detector.new
    end

    it 'detects features on the system based on #confine block' do
      features = detector.available_features
      assert features.find { |f| f.class == Features::PresentService },
             'failed to collect features that were initialized in `confine` block'

      TestHelper.use_present_service_2 = true
      detector.refresh
      features = detector.available_features
      assert features.find { |f| f.class == Features::PresentService2 },
             'failed to collect newer version of a feature'
    end

    it 'allows confining one feature based on present of other' do
      features = detector.available_features
      assert features.find { |f| f.class == Features::Server },
             'failed to collect features that were initialized in `confine` block'
      refute features.find { |f| f.class == Features::Client },
             'failed to detect feature that reference another feature in `confine` block'
    end

    it 'allows to filter checks based on metadata and present features' do
      checks = detector.available_checks(:basic)
      assert(checks.find { |c| c.is_a? Checks::PresentServiceIsRunning },
             'checks that should be found is missing')
      refute(checks.find { |c| c.is_a? Checks::MissingServiceIsRunning },
             'checks that should not be found are present')
    end

    it 'allows to filter scenarios based on metadata and present features' do
      scenarios = detector.available_scenarios(:tags => :upgrade)
      assert(scenarios.find { |c| c.is_a? Scenarios::PresentUpgrade },
             'scenarios that should be found is missing')
      refute(scenarios.find { |c| c.is_a? Scenarios::MissingUpgrade },
             'scenarios that should not be found are present')
    end
  end
end
