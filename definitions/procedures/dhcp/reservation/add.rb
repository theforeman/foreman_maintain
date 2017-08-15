module Procedures::Dhcp
  module Reservation
    class Add < ForemanMaintain::Procedure
      metadata do
        description 'add DHCP reservation to subnet'
        param :subnet, 'specify subnet to add reservation', :required => true
        param :ip, 'specify IP for new reservation', :required => true
        param :mac, 'specify mac address for new reservation', :required => true
        param :name, 'specify name for new reservation', :required => true
        for_feature :foreman_proxy_dhcp
        tags :dhcp_reservations
        label :dhcp_reservation_add
      end

      def run
        feature(:foreman_proxy_dhcp).add_reservation(@subnet, @ip, @mac, @name)
      end
    end
  end
end
