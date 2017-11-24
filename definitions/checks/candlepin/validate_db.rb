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
      feature(:candlepin_database).execute_cpdb_validate_cmd
    end
  end
end
