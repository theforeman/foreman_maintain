require_relative '../db_up_check'

module Checks
  module Pulpcore
    class DBUp < DBUpCheck
      metadata do
        description 'Make sure Pulpcore DB is up'
        label :pulpcore_db_up
        for_feature :pulpcore_database
      end

      def database_feature
        :pulpcore_database
      end

      def database_name
        'Pulpcore'
      end
    end
  end
end
