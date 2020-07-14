module Checks
  module Foreman
    class CheckForMysql < ForemanMaintain::Check
      metadata do
        label :check_for_mysql_db
        for_feature :foreman_server
        description 'Check if system is using MySQL database'
        confine do
          check_min_version('foreman', '1.24') && feature(:installer).answers['foreman-db-type'] == 'mysql'
        end
      end

      def run
        Procedures::KnowledgeBaseArticle.new(:doc => 'migrate_to_postgresql')
      end
    end
  end
end
