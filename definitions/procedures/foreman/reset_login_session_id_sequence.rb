module Procedures::Foreman
  class ResetLoginSessionIds < ForemanMaintain::Procedure
    metadata do
      description 'Reset Login Session Ids'
      for_feature :foreman_database
    end

    def run
      with_spinner('Reset the login session sequence:') do |spinner|
        spinner.update 'Reseting sessions id sequence'
        alter_sessions_id_seq
      end
    end

    def alter_sessions_id_seq
      feature(:foreman_database).psql(<<-SQL)
      BEGIN;
        ALTER SEQUENCE sessions_id_seq RESTART WITH 1;
      COMMIT;
      SQL
    end
  end
end
