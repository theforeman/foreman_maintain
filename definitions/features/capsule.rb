require 'features/foreman_proxy'

class Features::Capsule < Features::ForemanProxy
  metadata do
    label :capsule

    confine do
      # how it will show on dev setup?
      smart_proxy? && feature(:installer) && feature(:installer).last_scenario.eql?('capsule')
    end
  end

  def current_version
    @current_version ||= rpm_version('satellite-capsule')
  end
end
