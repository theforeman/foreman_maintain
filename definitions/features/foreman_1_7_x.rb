class Features::Foreman_1_7_x < ForemanMaintain::Feature
  metadata do
    label :foreman

    confine do
      check_min_version('foreman', '1.7')
    end
  end
end
