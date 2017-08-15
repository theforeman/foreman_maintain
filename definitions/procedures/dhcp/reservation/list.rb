module Procedures::Dhcp
  module Reservation
    class List < ForemanMaintain::Procedure
      metadata do
        description 'list DHCP reservations for subnet'
        param :subnet, 'specify subnet for listing reservations', :required => true
        for_feature :foreman_proxy_dhcp
        tags :dhcp_reservations
        label :dhcp_reservation_list
      end

      def run
        feature(:foreman_proxy_dhcp).list_reservations(@subnet)
      end
    end
  end
end
