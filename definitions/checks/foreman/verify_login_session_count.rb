module Checks
  module Foreman
    class VerifyLoginSessionCount < ForemanMaintain::Check
      metadata do
        label :foreman_login_session
        tags :default
        description 'Check the login session count'
        for_feature :foreman_database
      end

      # As session ID is of type integer, server can't add a new session record beyond 2151782969. Therefore assigning MAX_SESSION_ID to 2151782969/2.
      MAX_SESSION_ID = 1_075_891_484

      def run
        login_session_count = count
        assert(login_session_count <= MAX_SESSION_ID,
               "Login session count reached to #{login_session_count} i.e greater than"\
               " #{MAX_SESSION_ID} which will cause a problem while creating a new session."\
               ' It needs to reset login session sequence',
               :next_steps => Procedures::ResetLoginSessionIds.new)
      end

      def count
        sql = <<-SQL
        SELECT last_value FROM sessions_id_seq
        SQL
        feature(:foreman_database).query(sql).first['last_value'].to_i
      end
    end
  end
end
