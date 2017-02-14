require 'features/my_test_feature'
class Features::MyTestFeature_2 < Features::MyTestFeature
  label :my_test_feature

  detect do
    new if TestHelper.use_my_test_feature_2
  end
end
