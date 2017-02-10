require 'features/foreman_1_7_x'

class Features::Foreman_1_11_x < Features::Foreman_1_7_x
  detect do
    if check_min_version('foreman', '1.11')
      new
    end
  end
end
