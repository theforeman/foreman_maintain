module Checks::Candlepin
  class VerifyOrphanedRecordsFromEnvContent < ForemanMaintain::Check
    metadata do
      description 'Check to verify an orphaned record(s) present in cp_env_content table'
      tags :pre_upgrade

      confine do
        feature(:candlepin)
      end
    end

    def run
      content_ids = feature(:candlepin).content_ids_with_null_content_from_cp_env_content
      assert(content_ids.empty?,
             "#{content_ids.length} orphaned record(s) with null content found",
             :next_steps => Procedures::Candlepin::DeleteOrphanedRecordsFromEnvContent.new)
    end
  end
end
