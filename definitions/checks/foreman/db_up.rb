require_relative '../db_up_check'

module Checks
  module Foreman
    class DBUp < DBUpCheck
      metadata do
        description 'Make sure Foreman DB is up'
        label :foreman_db_up
        for_feature :foreman_database
      end

      def database_feature
        :foreman_database
      end

      def database_name
        'Foreman'
      end
    end
  end
end
