module Checks::Candlepin
  class ValidateDb < ForemanMaintain::Check
    metadata do
      description 'Check to validate candlepin database'
      tags :pre_upgrade

      confine do
        feature(:candlepin_database) && feature(:candlepin_database).validate_available_in_cpdb?
      end
    end

    def run
      result, result_msg = feature(:candlepin_database).execute_cpdb_validate_cmd
      next_steps = []
      if feature(:satellite) && feature(:satellite).current_minor_version == '6.2'
        next_steps.concat(
          [Procedures::Candlepin::DeleteOrphanedRecordsFromEnvContent.new,
           Procedures::KnowledgeBaseArticle.new(:doc => 'fix_cpdb_validate_failure')]
        )
      end
      assert(result == 0, result_msg, :next_steps => next_steps)
    end
  end
end
