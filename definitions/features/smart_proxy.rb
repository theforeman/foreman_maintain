require 'features/foreman_proxy'

class Features::SmartProxy < Features::ForemanProxy
  metadata do
    label :smart_proxy

    confine do
      smart_proxy?
    end
  end
end
