require 'test_helper'

module ForemanMaintain
  describe Detector do
    include ResetTestState

    let :detector do
      Detector.new
    end

    it 'detects features on the system based on #confine block' do
      features = detector.available_features(true)
      assert features.find { |f| f.class == Features::MyTestFeature },
             'failed to collect features that were initialized in `confine` block'

      TestHelper.use_my_test_feature_2 = true
      features = detector.available_features(true)
      assert features.find { |f| f.class == Features::MyTestFeature_2 },
             'failed to collect newer version of a feature'
    end

    it 'allows confining one feature based on present of other' do
      features = detector.available_features(true)
      assert features.find { |f| f.class == Features::Server },
             'failed to collect features that were initialized in `confine` block'
      refute features.find { |f| f.class == Features::Client },
             'failed to detect feature that reference another feature in `confine` block'
    end
  end
end
