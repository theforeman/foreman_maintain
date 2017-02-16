require 'features/foreman_1_7_x'

class Features::Foreman_1_11_x < Features::Foreman_1_7_x
  confine do
    check_min_version('foreman', '1.11')
  end
end
