require_relative '../db_up_check'

module Checks
  module Candlepin
    class DBUp < DBUpCheck
      metadata do
        description 'Make sure Candlepin DB is up'
        label :candlepin_db_up
        for_feature :candlepin_database
      end

      def database_feature
        :candlepin_database
      end

      def database_name
        'Candlepin'
      end
    end
  end
end
