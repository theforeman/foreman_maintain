module Checks
  module IopInventory
    class DBUp < ForemanMaintain::Check
      metadata do
        description 'Make sure IoP Inventory DB is up'
        label :iop_inventory_db_up
        for_feature :iop_inventory
      end

      def run
        status = false
        if feature(:iop_inventory_database).psql_cmd_available?
          with_spinner('Checking connection to the IoP Inventory DB') do
            status = feature(:iop_inventory_database).ping
          end
          assert(status, 'IoP Inventory DB is not responding. ' \
            'It needs to be up and running to perform the following steps',
            :next_steps => start_pgsql)
        else
          feature(:iop_inventory_database).raise_psql_missing_error
        end
      end

      def start_pgsql
        if feature(:iop_inventory_database).local?
          [Procedures::Service::Start.new(:only => 'postgresql')]
        else
          [] # there is nothing we can do for remote db
        end
      end
    end
  end
end
