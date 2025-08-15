module Checks
  module Foreman
    class DBIndex < ForemanMaintain::Check
      metadata do
        description 'Make sure Foreman DB indexes are OK'
        label :foreman_db_index
        tags :db_index
        for_feature :foreman_database
        confine do
          feature(:foreman_database)&.local?
        end
      end

      def run
        status, output = feature(:foreman_database).amcheck

        assert(status == 0, "Foreman DB indexes have issues:\n#{output}")
      end
    end
  end
end
