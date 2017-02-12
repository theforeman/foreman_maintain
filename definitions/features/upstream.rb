class Features::Foreman_1_7_x < ForemanMaintain::Feature
  feature_name :foreman

  detect do
    new if check_min_version('foreman', '1.7')
  end
end
