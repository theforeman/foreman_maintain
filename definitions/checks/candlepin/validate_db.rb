module Checks::Candlepin
  class ValidateDb < ForemanMaintain::Check
    metadata do
      description 'Check to validate candlepin database'
      tags :pre_upgrade

      confine do
        feature(:candlepin_database)&.validate_available_in_cpdb?
      end
    end

    def run
      result, result_msg = feature(:candlepin_database).execute_cpdb_validate_cmd
      assert(result == 0, result_msg)
    end
  end
end
