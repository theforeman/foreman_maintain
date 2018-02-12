module ForemanMaintain
  module Features
    class ForemanServer < ForemanMaintain::Feature
      metadata do
        label :foreman_server
        confine do
          server?
        end
      end

      def services
        {
          'postgresql'               => 5,
          'httpd'                    => 30
        }
      end
    end
  end
end
