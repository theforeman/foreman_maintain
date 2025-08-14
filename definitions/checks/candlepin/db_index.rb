module Checks
  module Candlepin
    class DBIndex < ForemanMaintain::Check
      metadata do
        description 'Make sure Candlepin DB indexes are OK'
        label :candlepin_db_index
        tags :db_index
        for_feature :candlepin_database
        confine do
          feature(:candlepin_database)&.local?
        end
      end

      def run
        status, output = feature(:candlepin_database).amcheck

        if !status.nil?
          assert(status == 0, "Candlepin DB indexes have issues:\n#{output}")
        else
          skip 'amcheck is not available in this setup'
        end
      end
    end
  end
end
