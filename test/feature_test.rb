require 'test_helper'

module ForemanMaintain
  describe Feature::Detector do
    include ResetTestState

    let :detector do
      Feature::Detector.new
    end

    it 'detects features on the system based on #detect block' do
      features = detector.available_features(true)
      assert features.find { |f| f.class == Features::MyTestFeature },
             'failed to collect features that were initialized in `detect` block'

      TestHelper.use_my_test_feature_2 = true
      features = detector.available_features(true)
      assert features.find { |f| f.class == Features::MyTestFeature_2 },
             'failed to collect newer version of a feature'
    end
  end
end
