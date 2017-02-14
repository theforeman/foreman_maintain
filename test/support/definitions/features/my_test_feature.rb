class Features::MyTestFeature < ForemanMaintain::Feature
  label :my_test_feature

  detect do
    # simulate this being always true
    new if 0.zero?
  end
end
