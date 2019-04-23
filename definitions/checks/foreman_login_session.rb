class Checks::ForemanLoginSession < ForemanMaintain::Check
  metadata do
    label :foreman_login_session
    tags :foreman_login_session
    description 'Check the login session count'
  end

  def run
    login_session_count = count()
    assert(login_session_count <= 2151782769,
               "Login session reached #{login_session_count}. Its better to clear the login session",
               :next_steps => Procedures::ForemanLoginSession.new())
  end

   def count()
    sql = <<-SQL
      SELECT last_value FROM sessions_id_seq
    SQL
	feature(:foreman_database).query(sql).first['last_value'].to_i

  end
end
