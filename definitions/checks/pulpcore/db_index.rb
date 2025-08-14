module Checks
  module Pulpcore
    class DBIndex < ForemanMaintain::Check
      metadata do
        description 'Make sure Pulpcore DB indexes are OK'
        label :pulpcore_db_index
        tags :db_index
        for_feature :pulpcore_database
        confine do
          feature(:pulpcore_database)&.local?
        end
      end

      def run
        status, output = feature(:pulpcore_database).amcheck

        assert(status == 0, "Pulpcore DB indexes have issues:\n#{output}")
      end
    end
  end
end
