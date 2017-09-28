module ForemanMaintain
  module Features
    class ForemanServer < ForemanMaintain::Feature
      metadata do
        label :foreman_server
        confine do
          server?
        end
      end
    end
  end
end
