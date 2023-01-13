module Procedures::Foreman
  class FixNicType < ForemanMaintain::Procedure
    metadata do
      advanced_run true
      description 'Fix NIC type from Nic::Base to Nic::Managed'
    end

    def run
      nics = feature(:foreman_database).query(sql_select)

      return unless nics.any?

      answer = ask_decision("Found #{nics.size} interfaces with 'Nic::Base' type.\n\n" \
       'Do you want update them to Nic::Managed type?', actions_msg: 'y(yes), q(quit)')

      abort! unless answer == :yes

      update_base_nics
    end

    private

    def sql_select
      <<-SQL
        SELECT id FROM nics WHERE type = 'Nic::Base'
      SQL
    end

    def update_base_nics
      feature(:foreman_database).psql(<<-SQL)
        UPDATE nics SET type = 'Nic::Managed' WHERE type = 'Nic::Base'
      SQL
    end
  end
end
