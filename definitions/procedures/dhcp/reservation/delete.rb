module Procedures::Dhcp
  module Reservation
    class Delete < ForemanMaintain::Procedure
      metadata do
        description 'delete DHCP reservation using subnet'
        param :subnet, 'specify subnet from which reservation', :required => true
        param :ip, 'specify subnet to delete reservation', :required => true
        for_feature :foreman_proxy_dhcp
        tags :dhcp_reservations
        label :dhcp_reservation_delete
      end

      def run
        feature(:foreman_proxy_dhcp).delete_reservation(@subnet, @ip)
      end
    end
  end
end
