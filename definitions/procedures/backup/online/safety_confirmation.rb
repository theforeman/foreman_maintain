module Procedures::Backup
  module Online
    class SafetyConfirmation < ForemanMaintain::Procedure
      metadata do
        description 'Data consistency warning'
        tags :backup
        param :include_db_dumps
      end

      def run
        answer = ask_decision(warning_message(@include_db_dumps), 'y(yes), q(quit)')
        abort! unless answer == :yes
      end

      def warning_message(include_db_dumps)
        substr = include_db_dumps ? 'database dump' : 'online backup'
        "*** WARNING: The #{substr} is intended for making a copy of the data\n" \
          '*** for debugging purposes only.' \
          " The backup routine can not ensure 100% consistency while the\n" \
          "*** backup is taking place as there is a chance there may be data mismatch between\n" \
          '*** Mongo and Postgres databases while the services are live.' \
          " If you wish to utilize the #{substr}\n" \
          '*** for production use you need to ensure that there are' \
          " no modifications occurring during\n" \
          "*** your backup run.\n\nDo you want to proceed?"
      end
    end
  end
end
