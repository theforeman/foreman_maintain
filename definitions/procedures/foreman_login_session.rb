class Procedures::ForemanLoginSession < ForemanMaintain::Procedure
  metadata do
    description 'Clean login sessions'
  end

  def run
    if alter_sessions_id_seq
      'DB Session cleared'
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
