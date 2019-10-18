module Checks
  module Foreman
    class CheckForMysql < ForemanMaintain::Check
      metadata do
        label :check_for_mysql_db
        for_feature :foreman_server
        description 'Check if system is using Mysql database'
        confine do
          check_min_version('foreman', '1.24') && feature(:foreman_database).mysql_db_in_use?
        end
      end

      def run
        Procedures::KnowledgeBaseArticle.new(:doc => 'migrate_to_postgresql')
      end
    end
  end
end
