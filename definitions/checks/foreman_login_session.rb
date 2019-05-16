class Checks::ForemanLoginSession < ForemanMaintain::Check
  metadata do
    label :foreman_login_session
    tags :default
    description 'Check the login session count'
  end

  # The max id value that we can't go beyond is 2151782969. 
  # Therefore setting MAX_SESSION_ID = 2151782969/2
  MAX_SESSION_ID = 1_075_891_484

  def run
    login_session_count = count
    assert(login_session_count <= MAX_SESSION_ID,
           "Login session reached #{login_session_count}. Its better to clear login sessions",
           :next_steps => Procedures::ForemanLoginSession.new)
  end

  def count
    sql = <<-SQL
    SELECT last_value FROM sessions_id_seq
    SQL
    feature(:foreman_database).query(sql).first['last_value'].to_i
  end
end
