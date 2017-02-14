class Features::MyTestFeature < ForemanMaintain::Feature
  label :my_test_feature
  autodetect

  confine do
    0.zero?
  end
end
