class Features::Foreman_1_7_x < ForemanMaintain::Feature
  label :foreman

  confine do
    check_min_version('foreman', '1.7')
  end
end
